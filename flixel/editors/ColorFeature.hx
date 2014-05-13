package flixel.editors;
import flixel.addons.ui.SwatchData;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * MetaData that maps a single color swatch to colorizable parts of an EntitySprite.
 * This can be something like "hat", or "pants" -- any part of the sprite.
 * This is principally used for when you want to create a user interface for re-coloring a sprite dynamically.
 * @author larsiusprime
 */
class ColorFeature implements IFlxDestroyable 
{

	public var name : String;			//name of the feature - "hat", "pants"
	
	public var colors:Array<Int>;		//array of indeces that maps sub-colors from the applied color swatch to list of colors in the actual EntitySkin
										//So say our ColorFeature.colors is:
										//
										//[2,3,4,-1]
										//
										//That means, when we look at our color swatch:
											//index 0: ("hilight")    --> this sub-color goes to index 2 in EntitySkin.colors
											//index 1: ("midtone")    --> this sub-color goes to index 3 in EntitySkin.colors
											//index 2: ("shadowMid")  --> this sub-color goes to index 4 in EntitySkin.colors
											//index 3: ("shadowDark") --> ignored, because value is -1
											
										//So say I have a color swatch with these values:
										//
										//[0xFFFFFF,0xDDDDDD,0xBBBBBB,0x999999]
										//
										//When colorization is applied, it will use the above mapping to produce this result:
												//index 0: ("hilight")    == 0xFFFFFF --> entitySkin.list_colors[2] = 0xFFFFFF;
												//index 1: ("midtone")    == 0xDDDDDD --> entitySkin.list_colors[3] = 0xDDDDDD;
												//index 2: ("shadowMid")  == 0xBBBBBB --> entitySkin.list_colors[4] = 0xBBBBBB;
												//index 3: ("shadowDark") == 0x999999 --> ignored
										//
										//This is only really important for pixelized sprites where you want one colors watch to affect multiple actual
										//color pixel values.
										//In an "HD-style" layered sprite, each color swatch will probably only affect ONE color layer.
	
	//Color Swatches can hold up to 10 sub-colors, and we give the shorthand name "hilight/midtone/shadowMid/shadowDark" to indeces 0-4 for convenience
	//Therefore, we create some handy getter/setters here as well. 
	//Note that these values are color mapping INDECES, not actual colors. They're just a fancier way of setting "colors[i] = j;"
	
	public var hilight(get,set):Int;				//remember, a value of -1 means "ignore this index"
	public var midtone(get,set):Int;				//and a value > 0 means "where to put this color swatch sub-color in entitySkin.list_colors"
	public var shadowMid(get,set):Int;
	public var shadowDark(get,set):Int;
	
	public function get_hilight():Int {
		if (colors.length >= 1) {
			return colors[0];
		}
		return -1;
	}
	public function set_hilight(Value:Int):Int {
		colors[0] = Value;
		return Value;
	}
	
	public function get_midtone():Int {
		if (colors.length >= 2) {
			return colors[1];
		}
		return -1;
	}
	public function set_midtone(Value:Int):Int {
		colors[1] = Value;
		return Value;
	}
	
	public function get_shadowMid():Int {
		if (colors.length >= 3) {
			return colors[2];
		}
		return -1;
	}
	public function set_shadowMid(Value:Int):Int {
		colors[2] = Value;
		return Value;
	}
	
	public function get_shadowDark():Int {
		if (colors.length >= 4) {
			return colors[3];
		}
		return -1;
	}
	public function set_shadowDark(Value:Int):Int {
		colors[3] = Value;
		return Value;
	}
	
	public var swatch : SwatchData;			//currently selected color swatch
	public var palette : ColorPalette;		//palette of possible swatches
	
	public var palette_name:String;			//palette name (for lookup purposes)
	
	/**
	 * Create a new ColorFeature for letting the user re-color the sprite
	 * @param	Name			Name of the ColorFeature, "hat", "pants", etc
	 * @param	?Colors			List of swatch->entitySkin color mapping indeces (optional)
	 * @param	?Palette_name	Name of the palette you'd eventually like to apply (optional)
	 * @param	?Pallete		The actual palette you're applying right now (optional)
	 * @param	?Swatch			ColorSwatch data that is currently selected (optional)
	 */
	
	public function new(Name:String, ?Colors:Array<Int>, ?Palette_name:String, ?Pallete:ColorPalette, ?Swatch:SwatchData) 
	{
		if (Colors == null) {
			colors = [];
		}else {
			colors = Colors;
		}
		name = Name;
		swatch = Swatch;
		palette_name = Palette_name;
		if (Pallete != null)
		{
			palette = Pallete;
		}
	}

	public function destroy() : Void
	{
		swatch = null;
		if (palette != null)
		{
			palette.destroy();
		}
		palette = null;
	}

	public function copy() : ColorFeature 
	{
		var cs : SwatchData = null;
		if (swatch != null)
		{
			cs = swatch.copy();
		}
		var pal : ColorPalette = null;
		if (palette != null)
		{
			pal = palette.copy();
		}
		return new ColorFeature(name, colors.copy(), palette_name, pal, cs);
	}

	public function toString() : String 
	{
		var str : String = "\nCF(" + name + ":" + hilight + "," + midtone + "," + shadowMid + "," + shadowDark +") ";
		str += "palette=\n..." + palette;
		return str;
	}

}

