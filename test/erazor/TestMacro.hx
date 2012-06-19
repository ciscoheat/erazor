package erazor;
import utest.Assert;
using erazor.macro.Tools;

/**
 * ...
 * @author Waneck
 */

class TestMacro 
{

	public function new() 
	{
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.setData(name = 'Boris').execute());
	}
/* not supported
	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.execute(vars));
	}
*/
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		var template = new MacroTest1();
		Assert.equals("  Hello Boris  \n ", template.setData(name = 'Boris').execute());
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		var template = new MacroTest2();
		Assert.equals("1-2-3-4-5-", template.setData(numbers = [1,2,3,4,5]).execute());

		var template = new MacroTest3();
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.setData(users = [{name:'Boris'}, {name:'Doris'}, {name: 'Someone else'}]).execute());
		
		var template = new MacroTest4();
		Assert.equals("987654321", template.execute());
		
		var template = new MacroTest5();
		Assert.equals("987654321", template.execute());
		
	}
	
	public function test_Static_method_call():Void
	{
		var template = new MacroTest6();
		Assert.equals("-1", template.setData(x = Math.PI).execute());
	}
	
	public function test_Block_with_enum_match():Void
	{
		var template = new MacroTest7();
		Assert.equals("object float instance of String ", template.setData(vars = untyped [ {}, Math.PI, "hello!" ]).execute());
	}
	
	public function test_Implicit_import():Void
	{
		var template = new MacroTest8();
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.setData(str = "Hello, World!").execute());
	}
	
	public function test_Explicit_import():Void
	{
		var template = new MacroTest9();
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.setData(str = "Hello, World!").execute());
	}
	
	public function test_Source_level_explicit_import():Void
	{
		var template = new MacroTest10();
		Assert.equals(Std.string(haxe.Int32.make(0x1234, 0x5678)), template.execute());
	}
}

@:template("Hello @name")
class MacroTest0 extends erazor.macro.Template
{
	public var name:String;
}

@:template("  Hello @name  \n ")
class MacroTest1 extends erazor.macro.Template
{
	public var name:String;
}

@:template("@for(i in numbers){@(i)-}")
class MacroTest2 extends erazor.macro.Template
{
	public var numbers:Array<Int>;
}

@:includeTemplate("Test.erazor")
class MacroTest3 extends erazor.macro.Template
{
	public var users:Array<{name:String}>;
}

@:template("@{ var a = 10; }@while(--a > 0){@a}")
class MacroTest4 extends erazor.macro.Template
{
	
}

@:template("@{var a = 9; var b = '9'; while(--a > 0){b += a;} }@b")
class MacroTest5 extends erazor.macro.Template
{
	
}

@:template("@Math.cos(x)")
class MacroTest6 extends erazor.macro.Template
{
	public var x:Float;
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
class MacroTest7 extends erazor.macro.Template
{
	public var vars:Array<Dynamic>;
}

@:template("@haxe.io.Bytes.ofString(str).toHex()")
class MacroTest8 extends erazor.macro.Template
{
	public var str:String;
}

@:template("@{var Bytes = haxe.io.Bytes;}@Bytes.ofString(str).toHex()")
class MacroTest9 extends erazor.macro.Template
{
	public var str:String;
}

import haxe.Int32;
@:template("@Int32.make(0x1234,0x5678)")
class MacroTest10 extends erazor.macro.Template
{
	
}

/*
@:includeTemplate('Test2.erazor')
class MacroTest11 extends erazor.macro.Template<Dynamic>
{
	
}*/