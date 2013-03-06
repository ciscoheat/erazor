package erazor;
import utest.Assert;
import haxe.Int64;
/**
 * ...
 * @author Waneck
 */

class TestSimpleMacro 
{

	public function new() 
	{
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		var template = new SimpleMacroTest0();
		Assert.equals('Hello Boris', template.setData({name: 'Boris'}).execute());
	}
/* not supported
	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		var template = new SimpleMacroTest0();
		Assert.equals('Hello Boris', template.execute(vars));
	}
*/
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		var template = new SimpleMacroTest1();
		Assert.equals("  Hello Boris  \n ", template.setData({name: 'Boris'}).execute());
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		var template = new SimpleMacroTest2();
		Assert.equals("1-2-3-4-5-", template.setData({numbers:[1,2,3,4,5]}).execute());

		var template = new SimpleMacroTest3();
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.setData({users: [{name:'Boris'}, {name:'Doris'}, {name: 'Someone else'}]}).execute());
		
		var template = new SimpleMacroTest4();
		Assert.equals("987654321", template.execute());
		
		var template = new SimpleMacroTest5();
		Assert.equals("987654321", template.execute());
		
	}
	
	public function test_Static_method_call():Void
	{
		var template = new SimpleMacroTest6();
		Assert.equals("-1", template.setData({x: Math.PI}).execute());
	}
	
	public function test_Block_with_enum_match():Void
	{
		var template = new SimpleMacroTest7();
		Assert.equals("object float instance of String ", template.setData({vars: untyped [ {}, Math.PI, "hello!" ] }).execute());
	}
	
	public function test_Implicit_import():Void
	{
		var template = new SimpleMacroTest8();
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.setData({str: "Hello, World!"}).execute());
	}
	
	public function test_Explicit_import():Void
	{
		var template = new SimpleMacroTest9();
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.setData({str: "Hello, World!"}).execute());
	}
	
	public function test_Source_level_explicit_import():Void
	{
		var template = new SimpleMacroTest10();
		Assert.equals(Std.string(haxe.Int64.make(0x1234, 0x5678)), template.execute());
	}
}

@:template("Hello @name")
class SimpleMacroTest0 extends erazor.macro.SimpleTemplate<{ name:String }>
{
}

@:template("  Hello @name  \n ")
class SimpleMacroTest1 extends erazor.macro.SimpleTemplate<{ name:String }>
{
}

@:template("@for(i in numbers){@(i)-}")
class SimpleMacroTest2 extends erazor.macro.SimpleTemplate<{ numbers:Array<Int> }>
{
}

@:includeTemplate("Test.erazor")
class SimpleMacroTest3 extends erazor.macro.SimpleTemplate<{ users: Array<{ name:String }> }>
{
}

@:template("@{ var a = 10; }@while(--a > 0){@a}")
class SimpleMacroTest4 extends erazor.macro.SimpleTemplate<{}>
{
	
}

@:template("@{var a = 9; var b = '9'; while(--a > 0){b += a;} }@b")
class SimpleMacroTest5 extends erazor.macro.SimpleTemplate<{}>
{
	
}

@:template("@Math.cos(x)")
class SimpleMacroTest6 extends erazor.macro.SimpleTemplate<{ x:Float }>
{
}

@:template("@for (_var in vars)
	{@{
			var x = switch(Type.typeof(_var))
			{
				case TObject: \"object \";
				case TFloat: \"float \";
				case TClass(i): \"instance of \" + Type.getClassName(i) + \" \";
				default: \"other \";
			}
		}@x}")
class SimpleMacroTest7 extends erazor.macro.SimpleTemplate<{ vars:Array<Dynamic> }>
{
	public var vars:Array<Dynamic>;
}

@:template("@haxe.io.Bytes.ofString(str).toHex()")
class SimpleMacroTest8 extends erazor.macro.SimpleTemplate<{ str:String }>
{
}

@:template("@{var Bytes = haxe.io.Bytes;}@Bytes.ofString(str).toHex()")
class SimpleMacroTest9 extends erazor.macro.SimpleTemplate<{ str:String }>
{
}

@:template("@Int64.make(0x1234,0x5678)")
class SimpleMacroTest10 extends erazor.macro.SimpleTemplate<{}>
{
	
}

/*
@:includeTemplate('Test2.erazor')
class SimpleMacroTest11 extends erazor.macro.SimpleTemplate<Dynamic>
{
	
}*/