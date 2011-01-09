package htemplate.hscript;   

import hscript.Interp;

class EnhancedInterp extends Interp
{
	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
		try { 
#if php    
//		if(null == args)
//			throw "null args";
//		args = args.concat([]);
//		php.Lib.print("<pre>");
//		php.Lib.dump(o);
//		php.Lib.dump(f);
//		php.Lib.dump(args);
//		args = args.concat([null, null, null, null, null]);
//		php.Lib.dump(untyped __field__(args, "»a"));
//		if(null == o)
//			return untyped __call__("call_user_func_array", f, __field__(args, "»a")); 
        return Reflect.callMethod(o,f,args);
#elseif neko 
		var n : Int = untyped __dollar__nargs(f);
		while(args.length < n)
			args.push(null); 
		return Reflect.callMethod(o,f,args);
#else
        return Reflect.callMethod(o,f,args);  
#end     
		} catch (e : Dynamic) { 
			trace(e + " " + f() + " " + args.length);
			return null;
		}
	}   
}