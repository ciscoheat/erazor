package htemplate.hscript;   

import hscript.Interp;

class EnhancedInterp extends Interp
{
	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
		return Reflect.callMethod(o,f,args.concat([null, null, null, null, null]));
	}
}