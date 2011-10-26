package erazor.macro;
import erazor.Parser;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
/**
 * ...
 * @author Waneck
 */

class Build 
{
	
	static function buildTemplate():Array<Field>
	{
		var cls = Context.getLocalClass().get();
		
		if (cls.superClass.t.toString() != "erazor.macro.Template")
			throw new Error("Cannot have extend another template.", cls.pos);
		
		var params = cls.superClass.params[0];
		
		var t = switch(Context.parse("{var _:" + typeToString(params) + ";}", cls.pos).expr)
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
					return build(s, meta.params[0].pos, t);
			}
		}
		
		throw new Error("No :template meta or :includeTemplate meta were found", cls.pos);
	}
	
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
	
	static function typeToString(type:Type):Null<String> 
	{
		if (type == null)
			return null;
		
		return switch(type)
		{
			case TMono( t ):
				var t2 = t.get();
				typeToString(t2);
			case TEnum( t, params ): t.toString() + args(params);
			case TInst( t, params ): t.toString() + args(params);
			case TType( t, params ): t.toString() + args(params);
			case TFun( args, ret ): Lambda.map(args, function(arg) return typeToString(arg.t)).join("->") + "->" + typeToString(ret);
			case TAnonymous( a ):
				var sbuf = new StringBuf();
				sbuf.add("{ ");
				var first = true;
				for (a in a.get().fields)
				{
					if (first) first = false; else sbuf.add(", ");
					sbuf.add(a.name);
					sbuf.add(" : ");
					sbuf.add(typeToString(a.type));
				}
				sbuf.add(" }");
				
				sbuf.toString();
			case TDynamic( t ):
				if (t != null)
					"Dynamic<" + typeToString(t) + ">";
				else
					"Dynamic";
#if haxe_209
			case TLazy( f ): typeToString(f());
#end
		}
	}
	
	static function args(args:Array<Type>):String 
	{
		if (args.length > 0)
		{
			return "<" + Lambda.map(args, typeToString).join(", ") + ">";
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
		var parsedBlocks = new Parser().parse(template);
		
		// Make a hscript with the buffer as context.
		var script = "{" + new ScriptBuilder('__b__').build(parsedBlocks) + "}";
		
		// Call macro string -> macro parser
		var expr = Context.parse(script, pos);
		
		// Change all top-level var use to use the context's
		var contextVar = "__context__";
		var defVars = new Hash();
		defVars.set("__b__", true);
		expr = changeExpr(expr, { expr:EConst(CIdent(contextVar)), pos:pos }, [defVars]);
		
		var fields = [];
		var executeBlock = [];
		
		var bvar = switch(Context.parse("{var __b__ = new StringBuf();}", pos).expr) 
		{
			case EBlock(b): b[0];
			default:throw "assert";
		};
		
		executeBlock.push(bvar);
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
	
	static function changeExpr(e:Null<Expr>, contextExpr:Expr, declaredVars:Array<Hash<Bool>>):Null<Expr>
	{
		if (e == null)
			return null;
		
		function _recurse(e:Expr)
		{
			return changeExpr(e, contextExpr, declaredVars);
		}
		
		var pos = e.pos;
		return switch(e.expr)
		{
			case EConst( c ):
				switch (c)
				{
					case CIdent(s):
						if (!lookupVar(s, declaredVars))
						{
							{expr:EField(contextExpr, s), pos:e.pos };
						} else {
							e;
						}
					case CType(s):
						if (!lookupVar(s, declaredVars))
						{
							{expr:EType(contextExpr, s), pos:e.pos };
						} else {
							e;
						}
					default: e;
				}
			case EArray( e1, e2 ): { expr:EArray(_recurse(e1), _recurse(e2)), pos:e.pos };
			case EBinop( op, e1, e2): { expr:EBinop(op, _recurse(e1), _recurse(e2)), pos:e.pos };
			case EField( e1, field ): { expr:EField(_recurse(e1), field), pos:e.pos };
			case EType( e1, field ): { expr:EType(_recurse(e1), field), pos:e.pos };
			case EParenthesis( e1 ):  { expr:EParenthesis(_recurse(e1)), pos:e.pos };
			case EObjectDecl( fields ): { expr:EObjectDecl(fields.map(function(f) return { field:f.field, expr:_recurse(f.expr) } ).array()), pos:e.pos };
			case EArrayDecl( values ): { expr:EArrayDecl(values.map(_recurse).array()), pos:e.pos };
			case ECall( e1, params): { expr:ECall(_recurse(e1), params.map(_recurse).array()), pos:e.pos };
			case ENew( t, params ): { expr:ENew(t, params.map(_recurse).array()), pos:e.pos};
			case EUnop( op, postFix, e1 ): { expr:EUnop(op, postFix, _recurse(e1)), pos:e.pos };
			case EVars( vars): { expr:EVars(vars.map(function(v) {
				addVar(v.name, declaredVars);
				return { name:v.name, type:v.type, expr:_recurse(v.expr) };
			}).array()), pos:e.pos };
			case EFunction( name, f ): { expr:EFunction(name, { args:f.args, ret:f.ret, expr:_recurse(f.expr), params:f.params } ), pos:e.pos };
			case EBlock( exprs ):
				declaredVars.push(new Hash());
				var ret = { expr:EBlock(exprs.map(_recurse).array()), pos:e.pos };
				declaredVars.pop();
				ret;
			case EFor( it, expr ): { expr:EFor(_recurse(it), _recurse(expr)), pos:e.pos };
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
				
				{ expr:EIn(_recurse(e1), _recurse(e2)), pos:e.pos };
			case EIf( econd, eif, eelse): { expr:EIf(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:e.pos };
			case EWhile( econd, e1, normalWhile ): { expr:EWhile(_recurse(econd), _recurse(e1), normalWhile), pos:e.pos };
			case ESwitch( e, cases, edef ):
				{expr:ESwitch(_recurse(e),
					cases.map(function(c) return {
						values:c.values.map(_recurse).array(),
						expr:_recurse(c.expr)
					}).array(), _recurse(edef)),
				pos:pos}
			case ETry( e , catches ): {expr:ETry(_recurse(e), catches.map(function(c) return { name:c.name, type:c.type, expr:_recurse(c.expr) } ).array()), pos:pos };
			case EReturn( e ): { expr:EReturn(_recurse(e)), pos:pos };
			case EBreak, EContinue: e;
			case EUntyped( e ): { expr:EUntyped(_recurse(e)), pos:pos };
			case EThrow( e ): { expr:EThrow(_recurse(e)), pos:pos };
			case ECast( e, t ): { expr:ECast(_recurse(e), t), pos:pos };
			case EDisplay( e, isCall ): { expr:EDisplay(_recurse(e), isCall), pos:pos };
			case EDisplayNew( t ): e;
			case ETernary( econd, eif, eelse ): { expr:ETernary(_recurse(econd), _recurse(eif), _recurse(eelse)), pos:pos };
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