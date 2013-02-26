package erazor.hscript;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class ReflectMacro {

	macro public static function addMeta( ?e:Dynamic ){
		Context.onGenerate( onGenerate );
		return { pos : Context.currentPos() , expr : EBlock([]) };
	}

	#if macro 
	public static function onGenerate( types : Array<Type> ){
		for( type in types ){
			switch( type ){
				case TInst( t , _ ) :
				
					for( f in t.get().fields.get() ){
						switch( f.kind ){
							case FVar( read , write ) :
								switch( read ){
									case AccCall( m ):
										f.meta.add( "get" , [{ pos : Context.currentPos(), expr : EConst(CString(m)) } ] , Context.currentPos() );
									default:
								}	
								switch( write ){
									case AccCall( m ):
										f.meta.add( "set" , [{ pos : Context.currentPos(), expr : EConst(CString(m)) } ] , Context.currentPos() );
									default:
								}
							default : 
						}
					}
				default :  
			}
		}
	}
	#end
}
