package flixel.editors;
import flixel.editors.EntityGraphics.EntityColorLayer;
import flixel.addons.ui.SwatchData;
import flixel.addons.ui.U;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;
import openfl.display.BlendMode;

/**
 * EntityGraphics objects let you share one set of AnimationData with multiple "skins" -- different looks for the same sprite.
 * You can differentiate skins by using different sprite sheets (assuming same animations), different dynamic color schemes,
 * or a combination of both.
 * @author larsiusprime
 */
class EntitySkin implements IFlxDestroyable
{

	public var name:String;						//string identifier
	public var path:String;						//path to asset within assets/gfx/ folder
	public var width:Int;						//width of frame
	public var height:Int;						//height of frame
	public var off_x:Int;						//x offset
	public var off_y:Int;						//y offset
	public var scaleX:Float=1;
	public var scaleY:Float=1;
	public var asset_src:String;				//filename sans extension
	public var asset_meta:String;				//metadata file (w/ extension), for atlases
	public var isDefault:Bool;					//is this the default skin
	public var blend:BlendMode;					//blend mode this skin uses
	public var color_change_mode:Int;			//color change method: COLOR_CHANGE_NONE, COLOR_CHANGE_LAYERS, COLOR_CHANGE_PIXELS
	public var custom_color_change_mode:String;			
	public var list_colors:Array<Int>;			//color change values, in correct sorting order (optional: works with PIXELS and LAYERS )
	public var list_original_pixel_colors:Array<Int>;						//original pixels for color change (optional: COLOR_CHANGE_PIXELS mode only)
	public var list_color_layers:Array<EntityGraphics.EntityColorLayer>;	//layer structure for color change (optional: COLOR_CHANGE_LAYERS mode only)
	public var list_color_features:Array<ColorFeature>;						//palette structure for color change
	
	public var using_structure:String = "";
	public var using_default_structure:Bool=false;							//whether we loaded our color structure from the default layout
	
	public function new() 
	{
	}
	
	public function destroy():Void {
		FlxArrayUtil.clearArray(list_colors);
		FlxArrayUtil.clearArray(list_original_pixel_colors);
		
		if (list_color_layers != null)
		{
			while (list_color_layers.length > 0)
			{
				list_color_layers.pop();
			}
		}
		
		FlxDestroyUtil.destroyArray(list_color_features);
		list_colors = null;
		list_original_pixel_colors = null;
		list_color_layers = null;
		list_color_features = null;
	}
	
	public function removeColorFeature(name:String):Void {
		if (list_color_features != null)
		{
			var match:ColorFeature = null;
			var i:Int = 0;
			for (cf in list_color_features)
			{
				if (cf.name == name)
				{
					match = cf;
					break;
				}
				i++;
			}
			
			if (match != null) {
				list_color_features.splice(i, 1);
				match.destroy();
			}else {
				//
			}
		}
	}
	
	public function getSwatchFromColorFeature(name:String):SwatchData {
		if (list_color_features != null)
		{
			var match:ColorFeature = null;
			for (cf in list_color_features)
			{
				if (cf.name == name)
				{
					match = cf;
					break;
				}
			}
			
			if (match != null && list_colors != null) 
			{
				var swatch:SwatchData = new SwatchData("",[0x00000000,0x00000000,0x00000000,0x00000000]);
				if(swatch.colors != null){
					for (i in 0...swatch.colors.length) {
						var indexInListColors:Int = -1;
						if (i < match.colors.length)
						{
							indexInListColors = match.colors[i];
						}
						if (indexInListColors >= 0 && indexInListColors < list_colors.length)
						{
							swatch.colors[i] = list_colors[match.colors[i]];
						}
					}
				}
				return swatch;
			}
		}
		return null;
	}
	
	public function addColorFeature(cf:ColorFeature):Void {
		if (list_color_features == null)
		{
			list_color_features = [];
		}	
		list_color_features.push(cf);
	}
	
	public function changeColorFeaturePalette(name:String, cp:ColorPalette, ?newName:String=""):Void {
		if (list_color_features != null)
		{
			var match:ColorFeature = null;
			for (cf in list_color_features)
			{
				if (cf.name == name)
				{
					match = cf;
					break;
				}
			}
			
			if (match != null)
			{
				if (match.palette != null)
				{
					match.palette.destroy();
					match.palette = null;
				}
				match.palette = cp;
				match.palette_name = cp.name;
				if (newName != "")
				{
					match.name = newName;
				}
			}
		}
	}
	
	public function replaceColorFeature(name:String, cf:ColorFeature):Void {
		if (list_color_features != null)
		{
			var match:ColorFeature = null;
			var i:Int = 0;
			for (cf in list_color_features)
			{
				if (cf.name == name)
				{
					match = cf;
					break;
				}
				i++;
			}
			
			if (match != null) 
			{
				match.destroy();
				list_color_features[i] = cf.copy();
			}
		}
	}
	
	/**
	 * 
	 * @param	name
	 * @param	data
	 * @return	whether the change resulted in a different palette
	 */
	public function changeColorFeature(name:String, data:SwatchData):Bool
	{
		var change = false;
		if (list_color_features != null)
		{
			var match:ColorFeature = null;
			for (cf in list_color_features)
			{
				if (cf.name == name)
				{
					match = cf;
					break;
				}
			}
			
			if (match != null) 
			{
				if (list_colors == null)
				{
					list_colors = [];
				}
				
				var i:Int = 0;
				for (cIndex in match.colors)
				{
					if (cIndex >= 0)
					{
						if (list_colors.length > cIndex && list_colors[cIndex] != data.colors[i])
						{
							change = true;
						}
						list_colors[cIndex] = data.colors[i];
					}
					i++;
				}
				
				//Avoid null integers!
				#if neko
					for (i in 0...list_colors.length)
					{
						if (list_colors[i] == null)
						{
							list_colors[i] = 0;
						}
					}
				#end 
			}
		}
		return change;
	}
	
	public function colorString():String
	{
		var str:String = "";
		var i:Int = 0;
		for (color in list_colors)
		{
			str += ("0x" + StringTools.hex(color, 6));
			if (i <= list_colors.length - 1)
			{
				str += ",";
			}
			i++;
		}
		return str;
	}
	
	public inline function copy():EntitySkin 
	{
		var copy = new EntitySkin();
		
		copy.name = name;
		copy.path = path;
		copy.width = width;
		copy.height = height;
		copy.off_x = off_x;
		copy.off_y = off_y;
		copy.scaleX = scaleX;
		copy.scaleY = scaleY;
		copy.asset_src = asset_src;
		copy.asset_meta = asset_meta;
		copy.isDefault = isDefault;
		copy.blend = blend;
		copy.color_change_mode = color_change_mode;
		copy.custom_color_change_mode = custom_color_change_mode;
		copy.using_default_structure = using_default_structure;
		copy.using_structure = using_structure;
		
		copy.list_original_pixel_colors = U.copy_shallow_arr_i(list_original_pixel_colors);
		copy.list_colors = U.copy_shallow_arr_i(list_colors);
		
		copy.list_color_layers = null;
		copy.list_color_features = null;
		
		if (list_color_features != null)
		{
			copy.list_color_features = [];
			for (cf in list_color_features)
			{
				copy.list_color_features.push(cf.copy());
			}
		}
		
		if (list_color_layers != null) {
			copy.list_color_layers = [];
			for (ecl in list_color_layers)
			{
				copy.list_color_layers.push(ecl.copy());
			}
		}
		
		return copy;
	}
	
	public function toXML():Fast
	{
		var xml:Xml = Xml.createElement("skin");
		xml.set("name", name);
		xml.set("default", Std.string(isDefault));
		xml.set("asset_src", asset_src);
		xml.set("asset_meta", asset_meta);
		xml.set("path", path);
		xml.set("width", Std.string(width));
		xml.set("height", Std.string(height));
		xml.set("off_x", Std.string(off_x));
		xml.set("off_y", Std.string(off_y));
		xml.set("scale_x", Std.string(scaleX));
		xml.set("scale_y", Std.string(scaleY));
		xml.set("blend", Std.string(blend));
		if (color_change_mode != EntityGraphics.COLOR_CHANGE_NONE) {
			var colors:Xml = Xml.createElement("colors");
			if (color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_BAKED) {
				colors.set("mode", "layers_baked");
			}else if (color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_STACKED) {
				colors.set("mode", "layers_stacked");
			}else if(color_change_mode == EntityGraphics.COLOR_CHANGE_PIXEL_PALETTE) {
				colors.set("mode", "pixels");
			}else if (color_change_mode == EntityGraphics.COLOR_CHANGE_CUSTOM) {
				colors.set("mode", "custom=" + custom_color_change_mode);
			}
			
			if (using_default_structure || using_structure != "")
			{
				if (using_default_structure)
				{
					colors.set("use_default", "true");
				}
				else
				{
					colors.set("use_structure", using_structure);
				}
			}
			else
			{
				if (list_color_features != null) {
					var cf:ColorFeature;
					for (cf in list_color_features) {
						var featureXml:Xml = Xml.createElement("feature");
						featureXml.set("name", cf.name);
						if (cf.palette != null) {
							featureXml.set("palette", cf.palette.name);	//palette DOT name (if we have object, read name from object)
						}else {
							featureXml.set("palette", cf.palette_name); //"palette_name" variable
						}
						
						var ci:Int = 0;
						for (colorInt in cf.colors) {
							featureXml.set("c" + ci, Std.string(colorInt));
							ci++;
						}
						colors.addChild(featureXml);
					}
				}
				if (list_color_layers != null) {
					var ecl:EntityColorLayer;
					for (ecl in list_color_layers) {
						var layerXml:Xml = Xml.createElement("layer");
						layerXml.set("name", ecl.name);
						layerXml.set("asset_src", ecl.asset_src);
						layerXml.set("asset_meta", ecl.asset_meta);
						if(ecl.alpha < 1){
							layerXml.set("alpha", Std.string(ecl.alpha));
						}
						layerXml.set("sort", Std.string(ecl.sort));
						colors.addChild(layerXml);
					}
				}
			}
			
			if (list_colors != null) {
				for (i in 0...list_colors.length) {
					var colorXml:Xml = Xml.createElement("color");
					var colorHex:String = hexColor(list_colors[i]);
					colorXml.set("value", colorHex);
					colorXml.set("index", Std.string(i));
					colors.addChild(colorXml);
				}
			}
			xml.addChild(colors);
		}
		return new Fast(xml);
	}
	
	private inline function hexColor(col:Int):String
	{
		return "0x" + StringTools.hex(col, 6);
	}
}