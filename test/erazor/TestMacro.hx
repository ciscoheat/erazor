package erazor;
import utest.Assert;
import haxe.Int64;
import erazor.Output;
using erazor.Output;
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
		template.name = 'Boris';
		Assert.equals('Hello Boris', template.execute());
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
		template.name = 'Boris';
		Assert.equals("  Hello Boris  \n ", template.execute());
	}

	public function test_If_keyword_vars_are_parsed_correctly()
	{
		var template = new MacroTest2();
		template.numbers = [1,2,3,4,5];
		Assert.equals("1-2-3-4-5-", template.execute());

		var template = new MacroTest3();
		template.users = [{name:'Boris'}, {name:'Doris'}, {name:'Someone else'}];
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.execute());

		var template = new MacroTest4();
		Assert.equals("987654321", template.execute());

		var template = new MacroTest5();
		Assert.equals("987654321", template.execute());

	}

	public function test_Static_method_call():Void
	{
		var template = new MacroTest6();
		template.x = Math.PI;
		Assert.equals("-1", template.execute());
	}

	public function test_Block_with_enum_match():Void
	{
		var template = new MacroTest7();
		template.vars = untyped [ {}, Math.PI, "hello!" ];
		Assert.equals("object float instance of String ", template.execute());
	}

	public function test_Implicit_import():Void
	{
		var template = new MacroTest8();
		template.str = "Hello, World!";
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.execute());
	}

	public function test_Explicit_import():Void
	{
		var template = new MacroTest9();
		template.str = "Hello, World!";
		Assert.equals(haxe.io.Bytes.ofString("Hello, World!").toHex(), template.execute());
	}

	public function test_Source_level_explicit_import():Void
	{
		var template = new MacroTest10();
		Assert.equals(Std.string(haxe.Int64.make(0x1234, 0x5678)), template.execute());
	}

	public function test_Identifiers()
	{
		var template = new MacroTest11();
		Assert.equals("Null Instance", template.execute());
		template.x = "Test";
		Assert.equals("Test", template.execute());
	}
	
	public function test_If_HtmlTemplate_strings_are_escaped()
	{
		var template = new MacroTest12();
		template.text = "< > & \" '";
		Assert.equals("&lt; &gt; &amp; &quot; &#039;", template.execute());
		
		var template2 = new MacroTest13();
		template2.users = ["admin", "<script>"];
		Assert.equals("<div>admin</div><div>&lt;script&gt;</div>", template2.execute());
	}
	
	public function test_If_HtmlTemplate_raw_works()
	{
		var template = new MacroTest14();
		template.text = "< > & \" '";
		Assert.equals("< > & \" '", template.execute());
		
		var template2 = new MacroTest15();
		template2.users = ["admin", "<script>"];
		Assert.equals("<div>admin</div><div><script></div>", template2.execute());
	}
	
	public function test_If_HtmlTemplate_SafeString_works()
	{
		var template = new MacroTest16();
		template.text = new SafeString("< > & \" '");
		Assert.equals("< > & \" '", template.execute());
		
		var template2 = new MacroTest17();
		template2.users = ["admin".safe(), "<script>".safe()];
		Assert.equals("<div>admin</div><div><script></div>", template2.execute());
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

@:template("@Int64.make(0x1234,0x5678)")
class MacroTest10 extends erazor.macro.Template
{

}

@:template("@if(x == null || false || !true){Null Instance} else {@x}")
class MacroTest11 extends erazor.macro.Template
{
	public var x:String;
}


@:template("@text")
class MacroTest12 extends erazor.macro.HtmlTemplate
{
	public var text:String;
}

@:template("@for(u in users){<div>@u</div>}")
class MacroTest13 extends erazor.macro.HtmlTemplate
{
	public var users:Array<String>;
}

@:template("@raw(text)")
class MacroTest14 extends erazor.macro.HtmlTemplate
{
	public var text:String;
}

@:template("@for(u in users){<div>@raw(u)</div>}")
class MacroTest15 extends erazor.macro.HtmlTemplate
{
	public var users:Array<String>;
}

@:template("@text")
class MacroTest16 extends erazor.macro.HtmlTemplate
{
	public var text:TString;
}

@:template("@for(u in users){<div>@u</div>}")
class MacroTest17 extends erazor.macro.HtmlTemplate
{
	public var users:Array<TString>;
}

/*
@:includeTemplate('Test2.erazor')
class MacroTest11 extends erazor.macro.Template<Dynamic>
{

}*/
