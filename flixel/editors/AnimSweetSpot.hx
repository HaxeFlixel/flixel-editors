package flixel.editors;
import flixel.addons.ui.FlxUI.NamedBool;
import flixel.util.FlxDestroyUtil;

/**
 * An extra bit of metadata for animation frames -- specifies the location of, e.g. spawnable
 * events/objects like when/where a punch lands, or when/where a bullet should happen
 * @author larsiusprime
 */
class AnimSweetSpot implements IFlxDestroyable
{
	public var x:Float;	//frame location associated with the sweet spot, if any
	public var y:Float;
	
	public var name:String;	//name associated with the sweet spot, if any
	
	public var meta:Map<String,Dynamic>;	//any other data
	
	public function new(name_:String="",x_:Float=-2,y_:Float=-1,?Meta:Map<String,Dynamic>) 
	{
		name = name_;
		x = x_;
		y = y_;
		meta = Meta;
	}
	
	public function copy():AnimSweetSpot
	{
		var metaCopy:Map<String,Dynamic>=null;
		if (meta != null)
		{
			metaCopy = new Map<String,Dynamic>();
			for (key in meta.keys()) {
				metaCopy.set(key, copyVal(meta.get(key)));
			}
		}
		return new AnimSweetSpot(name, x, y, metaCopy);
	}
	
	public function getMetaF(key:String):Float
	{
		if (meta.exists(key))
		{
			return cast meta.get(key);
		}
		return 0;
	}
	
	public function getMetaStr(key:String):String
	{
		if (meta.exists(key))
		{
			return cast meta.get(key);
		}
		return "";
	}
	
	public function getMetaI(key:String):Int
	{
		if (meta.exists(key))
		{
			return cast meta.get(key);
		}
		return 0;
	}
	
	public function toString():String
	{
		var str:String = "{name:" + name+", (" + x + "," + y + ")";
		if (meta == null)
		{
			str += "}";
		}
		else
		{
			str += ", meta:[";
			for (key in meta.keys())
			{
				str += key + ":" + meta.get(key) + ", ";
			}
			str = str.substr(0, str.length - 2);
			str += "]}";
		}
		return str;
	}
	
	public function copyVal(d:Dynamic):Dynamic
	{
		if (d == null || Std.is(d, Float) || Std.is(d, Int) || Std.is(d, Bool) || Std.is(d, String))
		{
			return d;
		}
		else
		{
			throw "can't deep-copy value(" + d + ")";
		}
		
		return null;
	}
	
	public function destroy():Void
	{
		if (meta != null)
		{
			for (key in meta.keys())
			{
				var thing = meta.get(key);
				if (Std.is(thing, IFlxDestroyable))
				{
					FlxDestroyUtil.destroy(thing);
					meta.remove(key);
					thing = null;
				}
			}
			meta = null;
		}
	}
}