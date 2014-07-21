package com.leveluplabs.tools.animator;
import flixel.addons.ui.U;
#if sys
	import systools.Dialogs;
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileInput;
	import sys.io.FileOutput;
#end
import flixel.editors.ColorIndex;
import haxe.xml.Fast;
/**
 * ...
 * @author larsiusprime
 */
class Do
{

	public function new() 
	{
		
	}
	
	
	#if sys
	public static function changeIndexPath(path:String):Void {
		Reg.path_index = path;
		writeIndex(Reg.path_index);
	}
	
	public static function readIndex():String
	{
		if (FileSystem.exists("config.xml") == false)
		{
			writeIndex("");
			return "";
		}
		else
		{
			var index:Fast = new Fast(Xml.parse(File.getContent("config.xml")).firstElement());
			if (index.hasNode.index)
			{
				var result:String = U.xml_str(index.node.index.x, "path");
				if (result == null || result.toLowerCase() == "null")
				{
					result = "";
				}
				return result;
			}
		}
		return "";
	}
	
	public static function readColorIndex():ColorIndex
	{
		var ci:ColorIndex= null;
		ci = new ColorIndex();
		var xml:Fast = U.readFast(Reg.path_index + Reg.path_entities + "\\" + "colors.xml");
		if (xml != null)
		{
			ci.fromXML(xml);
		}
		return ci;
	}
	
	public static function writeIndex(path:String):Void
	{
		var xml:Xml = Xml.parse('<index path="'+path+'"/>');
		U.writeXml(xml, "config.xml");
	}
	#end
}