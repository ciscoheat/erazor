package erazor.macro;
import erazor.error.ParserError;
import erazor.Parser;
import erazor.ScriptBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import neko.FileSystem;
import neko.io.File;

using Lambda;
/**
 * ...
 * @author Waneck
 */

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
		
		if (cls.superClass.t.toString() != "erazor.macro.Template")
		{
			//if someone is extending an already created macro template, it doesn't make sense for build() to execute
			return null;
		}
		
		var params = cls.superClass.params[0];
		
		//getting the class parameter and transforming it into a ComplexType
		var t = switch(Context.parse("{var _:" + typeToString(params, cls.pos) + ";}", cls.pos).expr)
		{
			case EBlock(b):
				switch(b[0].expr)
				{
					case EVars(v): v[0].type;
					default:null;
				}
			default:null;
		};
		
		for (meta in cls.meta.get())
		{
			switch(meta.name)
			{
				case ":template", "template":
					var s = getString(meta.params[0]);
					var pos = Context.getPosInfos(meta.params[0].pos);
					pos.min++;
					pos.max--;
					return build(s, Context.makePosition(pos), t);
				case ":includeTemplate", "includeTemplate":
					var srcLocation = Context.resolvePath(cls.module.split(".").join("/") + ".hx");
					var path = srcLocation.split("/");
					path.pop();
					
					var templatePath = getString(meta.params[0]);
					templatePath = path.join("/") + "/" + templatePath;
					
					if (! FileSystem.exists(templatePath)) throw new Error("File " + templatePath + " not found.", meta.params[0].pos);
					var contents = File.getContent(templatePath);
					var pos = Context.makePosition( { min:0, max:contents.length, file:templatePath } );
					
					return build(contents, pos, t);
			}
		}
		
		throw new Error("No :template meta or :includeTemplate meta were found", cls.pos);
#end
	}

#if !display
	static function getString(e:Expr, ?acceptIdent = false, ?throwExceptions = true):Null<String>
	{
		var ret = switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CString(s): s;
					case CIdent(s), CType(s): if (acceptIdent) s; else null;
					default: null;
				}
			default: null;
		}
		if (throwExceptions && ret == null)
			throw new Error("String type was expected", e.pos);
		return ret;
	}
	
	static function typeToString(type:Type, pos:Position):Null<String> 
	{
		if (type == null)
			return null;
		
		return switch(type)
		{
			case TMono( t ):
				var t2 = t.get();
				typeToString(t2, pos);
			case TEnum( t, params ): t.toString() + args(params, pos);
			case TInst( t, params ): t.toString() + args(params, pos);
			case TType( t, params ): t.toString() + args(params, pos);
			case TFun( args, ret ): Lambda.map(args, function(arg) return typeToString(arg.t, pos)).join("->") + "->" + typeToString(ret, pos);
			case TAnonymous( a ):
				var sbuf = new StringBuf();
				sbuf.add("{ ");
				var first = true;
				for (a in a.get().fields)
				{
					if (first) first = false; else sbuf.add(", ");
					
					var first = a.name.charCodeAt(0);
					if (first >= 'A'.code && first <= 'Z'.code)
					{
						Context.warning("Capitalized variables won't behave correctly inside an erazor macro context.", pos);
					}
					
					sbuf.add(a.name);
					sbuf.add(" : ");
					sbuf.add(typeToString(a.type, pos));
				}
				sbuf.add(" }");
				
				sbuf.toString();
			case TDynamic( t ):
				if (t != null)
					"Dynamic<" + typeToString(t, pos) + ">";
				else
					"Dynamic";
#if haxe_209
			case TLazy( f ): typeToString(f());
#end
		}
	}
	
	static function args(args:Array<Type>, pos):String 
	{
		if (args.length > 0)
		{
			return "<" + Lambda.map(args, function(t) return typeToString(t, pos)).join(", ") + ">";
		} else {
			return "";
		}
	}

	static function build(template:String, pos:Null<Position>, contextType:Null<ComplexType>):Array<Field>
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
		
		//trace(script);
		// Call macro string -> macro parser
		var expr = Context.parse(script, Context.makePosition({min:0, max:0, file:"_internal_"}));
		
		// Change all top-level var use to use the context's
		// And change the parsed script to take off all no-ops and set the right position values
		var contextVar = "__context__";
		var defVars = new Hash();
		//set our buffer and haxe keywords as a declared variable
		defVars.set("__b__", true);
		defVars.set("null", true);
		defVars.set("super", true);
		defVars.set("this", true);
		defVars.set("trace", true);
		defVars.set("true", true);
		defVars.set("false", true);
		expr = changeExpr(expr, { expr:EConst(CIdent(contextVar)), pos:pos }, [defVars], {info:null, carry:0, blockPos:blockPos});
		
		var fields = [];
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
			access:[APublic],
			kind:FFun({
				args:[{
					name:contextVar,
					opt:true,
					type:contextType,
					value:null
				}],
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
	static function changeExpr(e:Null<Expr>, contextExpr:Expr, declaredVars:Array<Hash<Bool>>, curPosInfo:{info:PosInfo, carry:Int, blockPos:Array<PosInfo>}, ?inCase = false, ?isType = false):Null<Expr>
	{
		if (e == null)
			return null;
		
		function _recurse(e:Expr)
		{
			return changeExpr(e, contextExpr, declaredVars, curPosInfo);
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
						if (inCase)
						{
							addVar(s, declaredVars);
							{expr:EConst(c), pos:pos(e.pos) };
						} else if (s == "__blockbegin__") 
						{
							var info = curPosInfo.blockPos.pop();
							var pos = Context.getPosInfos(e.pos);
							curPosInfo.info = info;
							
							curPosInfo.carry = pos.max - info.min - 3;
							{expr:EConst(CIdent("null")), pos:e.pos };
						} else if (!isType && !lookupVar(s, declaredVars)) {
							{expr:EField(contextExpr, s), pos:pos(e.pos) };
						} else {
							{expr:EConst(c), pos:pos(e.pos) };
						}
					default: {expr:EConst(c), pos:pos(e.pos) };
				}
			case EArray( e1, e2 ): { expr:EArray(_recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EBinop( op, e1, e2): { expr:EBinop(op, _recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EField( e1, field ): { expr:EField(changeExpr(e1, contextExpr, declaredVars, curPosInfo, false, isType), field), pos:pos(e.pos) };
			case EType( e1, field ): { expr:EType(changeExpr(e1, contextExpr, declaredVars, curPosInfo, false, true), field), pos:pos(e.pos) };
			case EParenthesis( e1 ):  { expr:EParenthesis(changeExpr(e1, contextExpr, declaredVars, curPosInfo, inCase, isType)), pos:pos(e.pos) };
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
								
								var ret = { expr:ECall(e1, params.map(function(e) return changeExpr(e, contextExpr, declaredVars, curPosInfo, inCase)).array()), pos:e.pos };
								curPosInfo.carry += 3;
								ret;
							}
						}
					default:
				}
				
				{ expr:ECall(_recurse(e1), params.map(function(e) return changeExpr(e, contextExpr, declaredVars, curPosInfo, inCase)).array()), pos:pos(e.pos) };
			case ENew( t, params ): { expr:ENew(t, params.map(_recurse).array()), pos:pos(e.pos)};
			case EUnop( op, postFix, e1 ): { expr:EUnop(op, postFix, _recurse(e1)), pos:pos(e.pos) };
			case EVars( vars): { expr:EVars(vars.map(function(v) {
				addVar(v.name, declaredVars);
				return { name:v.name, type:v.type, expr:_recurse(v.expr) };
			}).array()), pos:pos(e.pos) };
			case EFunction( name, f ): 
				addVar(name, declaredVars);
				declaredVars.push(new Hash());
				for (arg in f.args)
				{
					addVar(arg.name, declaredVars);
				}
				
				var ret = { expr:EFunction(name, { args:f.args, ret:f.ret, expr:_recurse(f.expr), params:f.params } ), pos:pos(e.pos) };
				declaredVars.pop();
				ret;
			case EBlock( exprs ):
				declaredVars.push(new Hash());
				var ret = { expr:EBlock(exprs.map(_recurse).array()), pos:pos(e.pos) };
				declaredVars.pop();
				ret;
			case EFor( it, expr ): { expr:EFor(_recurse(it), _recurse(expr)), pos:pos(e.pos) };
			case EIn( e1, e2 ): 
				switch(e1.expr)
				{
					case EConst(c):
						switch(c)
						{
							case CIdent(s), CType(s): addVar(s, declaredVars);
							default:
						}
					default:
				}
				
				{ expr:EIn(_recurse(e1), _recurse(e2)), pos:pos(e.pos) };
			case EIf( econd, eif, eelse): { expr:EIf(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:pos(e.pos) };
			case EWhile( econd, e1, normalWhile ): { expr:EWhile(_recurse(econd), _recurse(e1), normalWhile), pos:pos(e.pos) };
			case ESwitch( e, cases, edef ):
				{expr:ESwitch(_recurse(e),
					cases.map(function(c)
					{
						declaredVars.push(new Hash());
						var ret = {
							values:c.values.map(function(e) return changeExpr(e, contextExpr, declaredVars, curPosInfo, true)).array(),
							expr:_recurse(c.expr)
						};
						declaredVars.pop();
						return ret;
					}).array(), _recurse(edef)),
				pos:pos(e.pos)}
			case ETry( e , catches ): {expr:ETry(_recurse(e), catches.map(function(c) return { name:c.name, type:c.type, expr:_recurse(c.expr) } ).array()), pos:pos(e.pos) };
			case EReturn( e ): { expr:EReturn(_recurse(e)), pos:pos(e.pos) };
			case EBreak, EContinue: e;
			case EUntyped( e ): { expr:EUntyped(_recurse(e)), pos:pos(e.pos) };
			case EThrow( e ): { expr:EThrow(_recurse(e)), pos:pos(e.pos) };
			case ECast( e, t ): { expr:ECast(_recurse(e), t), pos:pos(e.pos) };
			case EDisplay( e, isCall ): { expr:EDisplay(_recurse(e), isCall), pos:pos(e.pos) };
			case EDisplayNew( t ): e;
			case ETernary( econd, eif, eelse ): { expr:ETernary(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:pos(e.pos) };
		}
	}
	
	static function addVar(name:String, declaredVars:Array<Hash<Bool>>):Void
	{
		declaredVars[declaredVars.length - 1].set(name, true);
	}
	
	static function lookupVar(name:String, declaredVars:Array<Hash<Bool>>):Bool
	{
		for (v in declaredVars)
		{
			if (v.exists(name))
				return true;
		}
		
		return false;
	}
}
#end