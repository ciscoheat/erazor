package erazor.macro;

/**
 * SimpleTemplate preserves the legacy erazor.macro.Template behaviour, by promoting a 'data' variable
 * @author waneck
 */
@:abstractTemplate class SimpleTemplate<T> extends Template
{
	@:promote public var data:T;
	
	public function setData(newData:T):SimpleTemplate<T>
	{
		this.data = newData;
		return this;
	}
}