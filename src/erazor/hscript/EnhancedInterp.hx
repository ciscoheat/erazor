package erazor.hscript;   

import hscript.Expr;
import hscript.Interp;

class EnhancedInterp extends Interp
{
#if flash9
	static var re = ~/(\d+)[^0-9]+\d+[^0-9]*$/;
#elseif php
	static var re = ~/^[^0-9]+(\d+)/;
#end
	override public function new(){
		super();
		//require StringBuf's add field
		var add = new StringBuf().add;
	}
	override function get( o : Dynamic, f : String ) : Dynamic {
		if( o == null ) throw Error.EInvalidAccess(f);
		
		return 
		#if getter_support
		 Reflect.getProperty(o,f);
		#else
		 Reflect.field( o , f );
		#end
	}
	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
#if php
		while (true)
		{
			try
			{
				return Reflect.callMethod(o,f,args);
			} catch (e : String) {
				if (e.substr(0, 16) != "Missing argument")
					php.Lib.rethrow(e);
				var expected = args.length + 1;
				if (re.match(e))
					expected = Std.parseInt(re.matched(1));
				if (expected > 15) // guard value
					throw "invalid number of arguments";
				else if (expected < args.length)
					args = args.slice(0, expected);
				else while (expected > args.length)
					args.push(null);
			}
		}
		return null;
#elseif js
		args = args.concat([null, null, null, null, null]);
		return Reflect.callMethod(o, f, args);
#elseif neko 
		var n : Int = untyped __dollar__nargs(f);
		while(args.length < n)
			args.push(null); 
		return Reflect.callMethod(o,f,args);
#elseif flash9
		while (true)
		{
			try
			{
				return Reflect.callMethod(o,f,args);
			} catch (e : flash.errors.Error) {
				var expected = re.match(e.message) ?  Std.parseInt(re.matched(1)) : args.length + 1;
				if (expected > 15) // guard value
					throw "invalid number of arguments";
				else if (expected < args.length)
					args = args.slice(0, expected);
				else while (expected > args.length)
					args.push(null);
			}
		}
		return null;
#else
        return Reflect.callMethod(o,f,args);  
#end     
	}  
#if php
	override public function expr( e : Expr ) : Dynamic {
		switch( e ) {
		case EFunction(params,fexpr,name,ret):
			var capturedLocals = duplicate(locals);
			var me = this;
			var f = function(args:Array<Dynamic>) {
				var old = me.locals;
				me.locals = me.duplicate(capturedLocals);
				for( i in 0...params.length )
					me.locals.set(params[i].name,{ r : args[i] });
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