class TestAll
{

	static function main()
	{
		var runner = new utest.Runner();
		
		runner.addCase(new htemplate.TestParser());
		runner.addCase(new htemplate.TestScriptBuilder());
		runner.addCase(new htemplate.TestTemplate());
		
		var report = new utest.ui.text.PrintReport(runner);
		runner.run();
	}
}