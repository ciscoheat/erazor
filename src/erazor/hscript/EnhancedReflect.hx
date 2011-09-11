package erazor.hscript;

import haxe.rtti.Meta;

class EnhancedReflect {
	
	public static function getProperty( o : Dynamic , field : String ){
		
		try{
			var meta = Meta.getFields( Type.getClass( o ) );
			var infos = Reflect.field( meta, field );
			if( infos != null ){
				var getter = infos.get;
				if( getter != null ) return Reflect.callMethod( o , Reflect.field( o , getter[0] ) , [] );
			}
		}catch(e:Dynamic){}
		
		return Reflect.field( o , field );
		
	}
}