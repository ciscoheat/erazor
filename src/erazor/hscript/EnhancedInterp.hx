package erazor.hscript;   

import hscript.Expr;
import hscript.Interp;

class EnhancedInterp extends Interp
{
	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
#if (php || js)
		args = args.concat([null, null, null, null, null]);
        return Reflect.callMethod(o,f,args);
#elseif neko 
		var n : Int = untyped __dollar__nargs(f);
		while(args.length < n)
			args.push(null); 
		return Reflect.callMethod(o,f,args);
#else
        return Reflect.callMethod(o,f,args);  
#end     
	}  
#if php
	override public function expr( e : Expr ) : Dynamic {
		switch( e ) {
		case EFunction(params,fexpr,name):
			var capturedLocals = duplicate(locals);
			var me = this;
			var f = function(args:Array<Dynamic>) {
				var old = me.locals;
				me.locals = me.duplicate(capturedLocals);
				for( i in 0...params.length )
					me.locals.set(params[i],{ r : args[i] });
				var r = null;
				try {
					r = me.exprReturn(fexpr);
				} catch( e : Dynamic ) {
					me.locals = old;
					throw e;
				}
				me.locals = old;
				return r;
			};
			var f = Reflect.makeVarArgs(f);
			if( name != null )
				variables.set(name,f);
			return f;
			default:
				return super.expr(e);
		}
		return null;
	}
#end
}