package erazor;

class TString {

	public var s : String;

	public function new( str ){
		this.s = str;
	}

	@:keep
	public function toString() {
		return s;
	}

}

typedef SafeString = TString;

class UnsafeString extends TString {
	
	public dynamic function escape( str ){
		return StringTools.htmlEscape( str, true );
	}
	
	public override function new( s , escapeMethod = null ){
		super( s );
		if( escapeMethod != null )
			escape = escapeMethod;
	}

	@:keep
	public override function toString(){
		return escape( s );
	}
}



class Output extends StringBuf {

	public function new( escapeMethod = null ){
		if( escapeMethod != null ) escape = escapeMethod;
		super();
	}

	public dynamic function escape( str ){
		return str;
	}

	public inline function unsafeAdd( str : Dynamic ){
		var val = if( Std.is( str , TString ) ){
			str.toString();
		}else{
			escape( Std.string( str ) );
		}

		add(val);
	}
	
	public static function safe( str : String ) {
		return new SafeString( str );
	}
	
	public static function unsafe( str : String ) {
		return new UnsafeString( str );
	}

}