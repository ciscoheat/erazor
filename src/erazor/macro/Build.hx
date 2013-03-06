package erazor.macro;
import erazor.error.ParserError;
import erazor.Parser;
import erazor.ScriptBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
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
			}
		}
		
		if (isFirst)
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
			#if !erazor_macro_debug
			//we'll include a no-op so we can distinguish the blocks.
			buildedBlocks.add("__blockbegin__;\n");
			#end
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
		
		#if erazor_macro_debug
		file = haxe.io.Path.withoutExtension(posInfo.file) + "_" + Context.getLocalClass().toString().split(".").pop() + "_debug.erazor";
		
		var w = File.write(file, false);
		w.writeString(script);
		w.close();
		#end
		
		// Call macro string -> macro parser
		var expr = Context.parse(script, Context.makePosition( { min:0, max:script.length, file:file } ));
		#if !erazor_macro_debug
		expr = changeExpr(expr, { info:null, carry:0, blockPos:blockPos } );
		#end
		
		var executeBlock = [];
		
		var bvar = switch(Context.parse("{var __b__ = new StringBuf();}", pos).expr) 
		{
			case EBlock(b): b[0];
			default:throw "assert";
		};
		
		//var __b__ = new StringBuf();
		executeBlock.push(bvar);
		//the executed script
		executeBlock.push(expr);
		executeBlock.push(Context.parse("return __b__.toString()", pos));
		
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
	
	//this internal function will traverse the AST and add a __context__ field access to any undeclared variable
	//it will also correctly set the position information for all constant types. This could also be extended to set the correct
	//position to any expression, but the most common error will most likely be in the constants part. (e.g. wrong variable name, etc)
	static function changeExpr(e:Null<Expr>, curPosInfo:{info:PosInfo, carry:Int, blockPos:Array<PosInfo>}):Null<Expr>
	{
		if (e == null)
			return null;
			
		function _recurse(e:Expr)
		{
			return changeExpr(e, curPosInfo);
		}
		
		function pos(lastPos:Position)
		{
			var info = curPosInfo.info;
			var pos = Context.getPosInfos(lastPos);
			var len = pos.max - pos.min;
			
			var min = pos.min - curPosInfo.carry;
			var ret = Context.makePosition( { file: info.file, min:min, max:min + len } );
			
			return ret;
		}
		
		return switch(e.expr)
		{
			case EConst( c ):
				switch (c)
				{
					case CIdent(s):
						if (s == "__blockbegin__") 
						{
							var info = curPosInfo.blockPos.pop();
							var pos = Context.getPosInfos(e.pos);
							curPosInfo.info = info;
							
							curPosInfo.carry = pos.max - info.min - 3;
							{expr:EConst(CIdent("null")), pos:e.pos };
						} else {
							{expr:EConst(c), pos:pos(e.pos) };
						}
					default: {expr:EConst(c), pos:pos(e.pos) };
				}
			case EArray( e1, e2 ): { expr:EArray(_recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EBinop( op, e1, e2): { expr:EBinop(op, _recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EField( e1, field ): { expr:EField(changeExpr(e1, curPosInfo), field), pos:pos(e.pos) };
			case EParenthesis( e1 ):  { expr:EParenthesis(changeExpr(e1, curPosInfo)), pos:pos(e.pos) };
			case EObjectDecl( fields ): { expr:EObjectDecl(fields.map(function(f) return { field:f.field, expr:_recurse(f.expr) } ).array()), pos:pos(e.pos) };
			case EArrayDecl( values ): { expr:EArrayDecl(values.map(_recurse).array()), pos:pos(e.pos) };
			case ECall( e1, params): 
				//we need to check if we find the expression __b__.add()
				//in order to not mess with the positions
				switch(e1.expr)
				{
					case EField(e, f):
						if (f == "add")
						{
							if (Std.string(e.expr) == "EConst(CIdent(__b__))")
							{
								var p = Context.getPosInfos(e1.pos);
								curPosInfo.carry += (p.max - p.min) + 2;
								
								var ret = { expr:ECall(e1, params.map(function(e) return changeExpr(e,curPosInfo)).array()), pos:e.pos };
								curPosInfo.carry += 3;
								ret;
							}
						}
					default:
				}
				
				{ expr:ECall(_recurse(e1), params.map(function(e) return changeExpr(e, curPosInfo)).array()), pos:pos(e.pos) };
			case ENew( t, params ): { expr:ENew(t, params.map(_recurse).array()), pos:pos(e.pos)};
			case EUnop( op, postFix, e1 ): { expr:EUnop(op, postFix, _recurse(e1)), pos:pos(e.pos) };
			case EVars( vars): { expr:EVars(vars.map(function(v) {
				return { name:v.name, type:v.type, expr:_recurse(v.expr) };
			}).array()), pos:pos(e.pos) };
			case EFunction( name, f ): 
				{ expr:EFunction(name, { args:f.args, ret:f.ret, expr:_recurse(f.expr), params:f.params } ), pos:pos(e.pos) };
			case EBlock( exprs ):
				{ expr:EBlock(exprs.map(_recurse).array()), pos:pos(e.pos) };
			case EFor( it, expr ): { expr:EFor(_recurse(it), _recurse(expr)), pos:pos(e.pos) };
			case EIn( e1, e2 ): 
				{ expr:EIn(_recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EIf( econd, eif, eelse): { expr:EIf(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:pos(e.pos) };
			case EWhile( econd, e1, normalWhile ): { expr:EWhile(_recurse(econd), _recurse(e1), normalWhile), pos:pos(e.pos) };
			case ESwitch( e, cases, edef ):
				{expr:ESwitch(_recurse(e),
					cases.map(function(c)
					{
						return {
							guard: _recurse(c.guard),
							values:c.values.map(function(e) return changeExpr(e, curPosInfo)).array(),
							expr:_recurse(c.expr)
						};
					}).array(), _recurse(edef)),
				pos:pos(e.pos)}
			case ETry( e , catches ): {expr:ETry(_recurse(e), catches.map(function(c) return { name:c.name, type:c.type, expr:_recurse(c.expr) } ).array()), pos:pos(e.pos) };
			case EReturn( e ): { expr:EReturn(_recurse(e)), pos:pos(e.pos) };
			case EBreak, EContinue: e;
			case EUntyped( e ): { expr:EUntyped(_recurse(e)), pos:pos(e.pos) };
			case EThrow( e ): { expr:EThrow(_recurse(e)), pos:pos(e.pos) };
			case ECast( e, t ): { expr:ECast(_recurse(e), t), pos:pos(e.pos) };
			case EDisplay( e, isCall ): { expr:EDisplay(_recurse(e), isCall), pos:pos(e.pos) };
			case EDisplayNew( _ ): e;
			case ETernary( econd, eif, eelse ): { expr:ETernary(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:pos(e.pos) };
			default: throw "Not implemented";
		}
	}
}
#end