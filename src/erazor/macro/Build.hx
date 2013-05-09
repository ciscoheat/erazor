package erazor.macro;
import erazor.error.ParserError;
import erazor.Parser;
import erazor.ScriptBuilder;
import haxe.ds.StringMap;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

using Lambda;

typedef PosInfo =
{
	file:String,
	max:Int,
	min:Int
}

class Build
{
	static function buildTemplate():Array<Field>
	{
#if display
		return null;
#else
		var cls = Context.getLocalClass().get();

		//is it the first template extension?
		var isFirst = true;
		if (cls.superClass.t.toString() != "erazor.macro.Template")
		{
			isFirst = false;
		}

		var params = cls.superClass.params[0];

		var fields = Context.getBuildFields();

		var isAbstract = false;
		for (meta in cls.meta.get())
		{
			switch(meta.name)
			{
				case ":template", "template":
					var s = getString(meta.params[0]);
					var pos = Context.getPosInfos(meta.params[0].pos);
					pos.min++;
					pos.max--;
					return build(s, Context.makePosition(pos), fields);
				case ":includeTemplate", "includeTemplate":
					var srcLocation = Context.resolvePath(cls.module.split(".").join("/") + ".hx");
					var path = srcLocation.split("/");
					path.pop();

					var templatePath = getString(meta.params[0]);
					templatePath = path.join("/") + "/" + templatePath;

					if (! FileSystem.exists(templatePath)) throw new Error("File " + templatePath + " not found.", meta.params[0].pos);

					Context.registerModuleDependency(Context.getLocalClass().get().module, templatePath);
					var contents = File.getContent(templatePath);
					var pos = Context.makePosition( { min:0, max:contents.length, file:templatePath } );

					return build(contents, pos, fields);
				case 'abstractTemplate', ':abstractTemplate': isAbstract = true;
			}
		}

		if (isFirst && !isAbstract)
			throw new Error("No :template meta or :includeTemplate meta were found", cls.pos);

		return fields;
#end
	}

#if !display
	public static function getString(e:Expr, ?acceptIdent = false, ?throwExceptions = true):Null<String>
	{
		var ret = switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CString(s): s;
					case CIdent(s): if (acceptIdent) s; else null;
					default: null;
				}
			default: null;
		}
		if (throwExceptions && ret == null)
			throw new Error("String type was expected", e.pos);
		return ret;
	}

	static function build(template:String, pos:Null<Position>, fields:Array<Field>):Array<Field>
	{
		if (pos == null)
		{
			pos = Context.currentPos();
		}

		// Parse the template into TBlocks for the HTemplateParser
		var parsedBlocks = null;
		try
		{
			parsedBlocks = new Parser().parseWithPosition(template);
		}

		//if a ParserError is found, bubble up but add the correct macro position to it.
		catch (e:ParserError)
		{
			var pos = Context.getPosInfos(pos);
			pos.min += e.pos;
			throw new Error("Parser error: \"" + e.toString() + "\"", Context.makePosition(pos));
		}

		var buildedBlocks = new StringBuf();
		buildedBlocks.add("{");
		var builder = new ScriptBuilder('__b__');
		for (block in parsedBlocks)
		{
			//we'll include a no-op so we can distinguish the blocks.
			buildedBlocks.add("__blockbegin__;\n");
			buildedBlocks.add(builder.blockToString(block.block));
		}
		buildedBlocks.add("}");

		var posInfo = Context.getPosInfos(pos);
		var min = posInfo.min;
		var blockPos = parsedBlocks.map(function(block) return { file:posInfo.file, min:min + block.start, max:min + block.start + block.length } ).array();
		blockPos.reverse();

		// Make a hscript with the buffer as context.
		var script = buildedBlocks.toString();

		var file = "_internal_";

		var declaredVars = [for (v in ["this","null","true","false","trace","__b__","super"]) v => true], promotedField = null;
		for (f in fields)
		{
			declaredVars.set(f.name, true);
			if (f.meta.exists(function(m) return m.name == "promote" || m.name == ":promote"))
			{
				if (promotedField == null)
					promotedField = f.name;
				else
					Context.error("Only one promoted field is allowed, but '" + promotedField +"' and '" + f.name + "' were declared", f.pos);
			}
		}

		//now add all declaredVars from superclasses
		var shouldLookSuper = promotedField == null;
		function loop(c:Ref<ClassType>, isFirst:Bool)
		{
			var c = c.get();
			if (!isFirst && shouldLookSuper)
			{
				shouldLookSuper = c.meta.has("abstractTemplate") || c.meta.has(":abstractTemplate");
			}

			for (f in c.fields.get())
			{
				if (shouldLookSuper && (f.meta.has(':promote') || f.meta.has('promote')))
				{
					promotedField = f.name;
					shouldLookSuper = false;
				} else {
					declaredVars.set(f.name, true);
				}
			}

			var sc = c.superClass;
			if (sc != null)
			{
				loop(sc.t, false);
			}
		}
		loop(Context.getLocalClass(), true);

		// Call macro string -> macro parser
		var expr = Context.parse(script, Context.makePosition( { min:0, max:script.length, file:file } ));
		expr = new MacroBuildMap(blockPos, promotedField, declaredVars).map(expr);

		#if erazor_macro_debug
		file = haxe.io.Path.withoutExtension(posInfo.file) + "_" + Context.getLocalClass().toString().split(".").pop() + "_debug.erazor";

		var w = File.write(file, false);
		var str = ExprTools.toString(expr);
		w.writeString(str);
		w.close();

		expr = Context.parse(str, Context.makePosition( { min:0, max:str.length, file: file } ));
		#end

		var executeBlock = [];

		executeBlock.push(macro var __b__ = new StringBuf());
		executeBlock.push(expr);
		executeBlock.push(macro return __b__.toString());

		//return new execute() field
		fields.push({
			name:"execute",
			doc:null,
			access:[APublic, AOverride],
			kind:FFun({
				args:[],
				ret:null,
				expr:{expr:EBlock(executeBlock), pos:pos},
				params:[]
			}),
			pos:pos,
			meta:[]
		});

		return fields;
	}
}

class MacroBuildMap
{
	var info:PosInfo;
	var carry:Int;
	var blockPos:Array<PosInfo>;
	var promotedField:Null<Expr>;

	var declaredVars:Array<StringMap<Bool>>;

	public function new(blockPos, promotedField:String, declaredVars)
	{
		this.carry = 0;
		this.blockPos = blockPos;
		this.declaredVars = [ declaredVars ];
		if (promotedField != null)
			this.promotedField = { expr: EConst(CIdent(promotedField)), pos: Context.currentPos() };
	}

	function lookupVar(name:String)
	{
		for (v in declaredVars)
			if (v.exists(name))
				return true;
		return false;
	}

	function pos(lastPos:Position)
	{
		var info = info;
		var pos = Context.getPosInfos(lastPos);
		var len = pos.max - pos.min;

		var min = pos.min - carry;
		var ret = Context.makePosition( { file: info.file, min:min, max:min + len } );

		return ret;
	}

	public function map(e:Expr):Expr
	{
		if (e == null) return null;
		return switch(e.expr)
		{
		case EConst(CIdent("__blockbegin__")):
			var info = blockPos.pop();
			var pos = Context.getPosInfos(e.pos);
			this.info = info;

			carry = pos.max - info.min - 3;
			{expr:EConst(CIdent("null")), pos:e.pos };
		case EConst(CIdent(s)) if (promotedField == null || (s.charCodeAt(0) >= 'A'.code && s.charCodeAt(0) <= 'Z'.code) || lookupVar(s)):
			{expr:EConst(CIdent(s)), pos:pos(e.pos) };
		case EConst(CIdent(s)):
			{expr:EField(promotedField, s), pos:pos(e.pos) }
		//we need to check if we find the expression __b__.add()
		//in order to not mess with the positions
		case ECall(e1 = macro __b__.add, params): //behold the beauty of pattern matching!
			var p = Context.getPosInfos(e1.pos);
			carry += (p.max - p.min) + 2;

			var ret = { expr:ECall(macro __b__.add, params.map(map)), pos:e.pos };
			carry += 3;
			ret;
		case EVars(vars):
			for (v in vars)
				addVar(v.name);
			var ret = ExprTools.map(e, map);
			ret.pos = pos(ret.pos);
			ret;
		case EFunction(name, f):
			if (name != null)
				addVar(name);
			pushStack([ for (arg in f.args) arg.name => true ]);
			var ret = ExprTools.map(e, map);
			ret.pos = pos(ret.pos);
			popStack();
			ret;
		case EBlock(_):
			pushStack();
			var ret = ExprTools.map(e, map);
			ret.pos = pos(ret.pos);
			popStack();
			ret;
		case EField(e1, f) if (promotedField != null):
			//check all fields first
			var hasTypeFields = f.charCodeAt(0) >= 'A'.code && f.charCodeAt(0) <= 'Z'.code;
			function checkField(e:Expr)
			{
				switch(e.expr)
				{
				case EField(_, f) | EConst(CIdent(f)) if (f.charCodeAt(0) >= 'A'.code && f.charCodeAt(0) <= 'Z'.code):
					hasTypeFields = true;
					ExprTools.iter(e, checkField);
				case EParenthesis(_), EField(_, _): //continue looking
					ExprTools.iter(e, checkField);
				case EConst(CIdent(_)):
				default: //stop looking; isn't a type field
					hasTypeFields = false;
				}
			}
			checkField(e1);
			if (hasTypeFields)
			{
				var old = this.promotedField;
				this.promotedField = null;
				var ret = ExprTools.map(e, map);
				ret.pos = pos(ret.pos);
				this.promotedField = old;
				ret;
			} else {
				var ret = ExprTools.map(e, map);
				ret.pos = pos(ret.pos);
				ret;
			}
		case ESwitch(e1, cases, edef):
			cases = cases.map(function(c) {
				pushStack();
				for (v in c.values) addIdents(v);
				var ret = {
					values: c.values,
					guard: map(c.guard),
					expr: map(c.expr)
				};
				popStack();
				return ret;
			});
			{ expr: ESwitch(map(e1), cases, map(edef)), pos: pos(e.pos) };
		case ETry(e1, catches):
			catches = catches.map(function(c) {
				pushStack([c.name => true]);
				var ret = { type: c.type, name:c.name, expr: map(c.expr) };
				popStack();
				return ret;
			});
			{ expr: ETry(map(e1), catches), pos: pos(e.pos) };
		case EFor( { expr: EIn(e1, _) }, _):
			pushStack();
			addIdents(e1);
			var ret = ExprTools.map(e, map);
			popStack();
			ret.pos = pos(ret.pos);
			return ret;
		default:
			var ret = ExprTools.map(e, map);
			ret.pos = pos(ret.pos);
			return ret;
		}
	}

	function addIdents(e:Expr)
	{
		switch(e.expr)
		{
		case EConst(CIdent(s)) if (s.charCodeAt(0) < 'A'.code || s.charCodeAt(0) > 'Z'.code): addVar(s);
		default: ExprTools.iter(e, addIdents);
		}
	}

	function addVar(v:String)
	{
		declaredVars[declaredVars.length - 1].set(v, true);
	}

	function pushStack(?map)
	{
		if (map == null) map = new StringMap();
		declaredVars.push(map);
	}

	function popStack()
	{
		declaredVars.pop();
	}
}
#end
