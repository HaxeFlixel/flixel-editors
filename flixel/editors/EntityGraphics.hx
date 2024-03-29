package flixel.editors;
import flixel.FlxG;
import flixel.editors.EntityGraphics.EntityColorLayer;
import flixel.editors.EntitySkin;
import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.U;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;
import openfl.Assets;
#if sys
import sys.FileSystem;
#end

/**
 * All the MetaData you need to make an EntitySprite
 * @author 
 */
class EntityGraphics implements IFlxDestroyable
{
	public var name:String;								//string identifier
	public var asset_src(get, null):String = "";		//the path to the asset file you want
	public var skinName:String = "";					//the string name of the desired EntitySkin (set this to change it)
	
	public var remotePath:String = "";					//if this is not "", then it will load from file instead of from Assets
	
	public var skin(get, null):EntitySkin;				//the currently selected EntitySkin
	public var map_skins:Map<String,EntitySkin>;		//all possible skins, maps string names ("hero") to skin data
	public var animations:Map<String,AnimationData>;	//all animations, maps string names ("walk_left") to animation data
	
	public var facings:Array<Facing>;
	public var defaultFacing:Facing = Facing.NONE;
	
	public static inline var COLOR_CHANGE_NONE:Int = 0;				//don't change colors on the base asset
	public static inline var COLOR_CHANGE_LAYERS_BAKED:Int = 1;		//it's an "HD style" layered sprite, change colors by colorizing & compositing layers
	public static inline var COLOR_CHANGE_PIXEL_PALETTE:Int = 2;	//it's a pixel-sprite, change colors by palette-swapping exact pixel color values
	public static inline var COLOR_CHANGE_LAYERS_STACKED:Int = 3;	//it's an "HD style" layered sprite, change colors by colorizing & stacking layers
	public static inline var COLOR_CHANGE_CUSTOM:Int = 4;	//it's an "HD style" layered sprite, change colors by colorizing & stacking layers
	
	public var scaleX:Float = 1.0;
	public var scaleY:Float = 1.0;
	
	public var scaleSmooth:Bool = true;
	public var scaleWithHardware:Bool = false;			//If true, scales using the scale property, if false, uses BitmapData.draw()
	
	public var colorKey(get, null):String;				//Returns a unique identifier for the current skin (combination of asset file(s) + custom color rules)
														//examples: 
														//  "assets/gfx/defenders/dude+pants#FF0000+hat#0000FF+shirt#00FF00" (HD layered sprite)
														//  "assets/gfx/defenders/dude#FF0000+#0000FF+#00FF00"				 (pixel sprite)
	
	public var scaledColorKey(get, null):String;		//Returns a unique identifier for the current skin AT the current scale
	
														
	public var ignoreColor:Null<FlxColor>=null;	//color that should be ignored during replacement logic
	
	/**********GETTER/SETTERS*************/
	
	public function get_asset_src():String
	{
		if (skin != null) {
			return skin.path + "/" + skin.asset_src;
		}
		return null;
	}
	
	public function get_skin():EntitySkin
	{
		if (map_skins != null && map_skins.exists(skinName))
		{
			return map_skins.get(skinName);
		}
		return null;
	}
	
	public function get_colorKey():String
	{
		var key:String = U.gfx(asset_src);
		var i:Int = 0;
		var color:Int = 0;
		
		if ((skin.color_change_mode == COLOR_CHANGE_LAYERS_BAKED) && skin.list_color_layers != null && skin.list_colors != null) 
		{
			for (layer in skin.list_color_layers)
			{
				if (i < skin.list_colors.length)
				{
					color = skin.list_colors[i];
					if (layer.asset_src != null && layer.asset_src != "")
					{
						key += layer.asset_src + color;
					}
				}
				i++;
			}
		}
		else if (skin.color_change_mode == COLOR_CHANGE_PIXEL_PALETTE && skin.list_original_pixel_colors != null && skin.list_colors != null) 
		{
			for (color in skin.list_colors) 
			{
				key += ","+color;
			}
		}
		
		//for COLOR_CHANGE_LAYERS_STACKED, return the base asset key alone -- no special baking required
		
		return key;
	}
	
	public function getScaleSuffix():String
	{
		var sX:Float = scaleX;
		var sY:Float = scaleY;
		if (skin != null)
		{
			sX *= skin.scaleX;
			sY *= skin.scaleY;
		}
		return "_sX:" + sX + "_sY:" + sY;
	}
	
	public function get_scaledColorKey():String
	{
		var ck:String = colorKey;
		return ck + getScaleSuffix();
	}
	
	public function new() {}
	
	public function destroy():Void {
		name = "";
		asset_src = "";
		skinName = "";
		remotePath = "";
		for (key in map_skins.keys())
		{
			var s:EntitySkin = map_skins.get(key);
			s.destroy();
			map_skins.remove(key);
		}
		
		for (key in animations.keys())
		{
			var ad:AnimationData = animations.get(key);
			ad.destroy();
			animations.remove(key);
		}
		
		ignoreColor = null;
	}
	
	public function countSkins():Int 
	{
		var i:Int = 0;
		for(key in map_skins.keys()) {
			i++;
		}
		return i;
	}
	
	public function getDefaultSkin():EntitySkin 
	{
		for (key in map_skins.keys()) {
			var skin:EntitySkin = map_skins.get(key);
			if (skin.isDefault) {
				return skin;
			}
		}
		return null;								//this should never happen if everything works correctly
	}
	
	public function getAnimationList():Array<StrNameLabel>
	{
		var strNames:Array<StrNameLabel> = [];
		for (key in animations.keys())
		{
			var strName:StrNameLabel = new StrNameLabel(key, key);
			strNames.push(strName);
		}
		strNames.sort(StrNameLabel.sortByLabel);
		return strNames;
	}
	
	public function hasSkin(name:String):Bool
	{
		return map_skins.exists(name);
	}
	
	public function getSkins():Array<EntitySkin>
	{
		var arr = [];
		for (key in map_skins.keys()) {
			arr.push(map_skins.get(key));
		}
		return arr;
	}
	
	public function getSkinNames():Array<String>
	{
		var arr = [];
		for (key in map_skins.keys()) {
			arr.push(map_skins.get(key).name);
		}
		return arr;
	}
	
	public function getSkinList():Array<StrNameLabel> {
		var strNames:Array<StrNameLabel> = [];
		for (key in map_skins.keys()) {
			var strId:StrNameLabel = new StrNameLabel(key, key);
			strNames.push(strId);
		}
		strNames.sort(StrNameLabel.sortByLabel);
		return strNames;
	}
	
	public function copy():EntityGraphics
	{
		var eg:EntityGraphics = new EntityGraphics();
		
		eg.name = name;
		eg.asset_src = asset_src;
		eg.skinName = skinName;
		eg.remotePath = remotePath;
		
		if (facings != null)
		{
			eg.facings = facings.copy();
		}
		
		if (map_skins != null)
		{
			eg.map_skins = new Map<String,EntitySkin>();
			for (key in map_skins.keys()){
				var oldSkin = map_skins.get(key);
				eg.map_skins.set(key, oldSkin.copy());
			}
		}
		if (animations != null)
		{
			eg.animations = new Map<String, AnimationData>();
			for (key in animations.keys()){
				var anim = animations.get(key);
				if (anim != null){ anim = anim.copy(); }
				eg.animations.set(key, anim);
			}
		}
		
		eg.defaultFacing = defaultFacing;
		
		eg.scaleX = scaleX;
		eg.scaleY = scaleY;
		eg.scaleSmooth = scaleSmooth;
		eg.scaleWithHardware = scaleWithHardware;
		eg.ignoreColor = ignoreColor;
		
		return eg;
	}
	
	public function toXML():Fast {
		
		var root:Xml = Xml.createDocument();
		var xml:Fast = new Fast(root);
		
		var gfxXml:Xml = Xml.createElement("graphic");
		gfxXml.set("name", name);
		
		root.addChild(gfxXml);
		
		var facingXml:Xml = Xml.createElement("facing");
		var facingStr:String = "";
		var f:Facing;
		var i:Int = 0;
		for (f in facings)
		{
			facingStr += f.toDirectionStr();
			if (i != facings.length - 1)
			{
				facingStr += ",";
			}
			i++;
		}
		facingXml.set("value", facingStr);
		facingXml.set("default", defaultFacing.toDirectionStr());
		gfxXml.addChild(facingXml);
		
		for (key in animations.keys()) {
			var anim:AnimationData = animations.get(key);
			var animXml:Xml = Xml.createElement("anim");
			animXml.set("name", anim.name);
			animXml.set("framerate", Std.string(anim.frameRate));
			animXml.set("looped", Std.string(anim.looped));
			animXml.set("flipX", Std.string(anim.flipX));
			animXml.set("flipY", Std.string(anim.flipY));
			for (i in 0...anim.frames.length) {
				var frameXml:Xml = Xml.createElement("frame");
				frameXml.set("value", Std.string(anim.frames[i]));
				if (anim.hasSweetSpot(i)) {
					var sweet:AnimSweetSpot = anim.getSweetSpot(i);
					frameXml.set("sweet", "true");
					
					if(sweet.x != 0){
						frameXml.set("x", Std.string(sweet.x));
					}
					if(sweet.y != 0){
						frameXml.set("y", Std.string(sweet.y));
					}
					if (sweet.name != "" && sweet.name != null) {
						frameXml.set("name", sweet.name);
					}
				}
				animXml.addChild(frameXml);
			}
			gfxXml.addChild(animXml);
		}
		
		for (key in map_skins.keys())
		{
			var s:EntitySkin = map_skins.get(key);
			var skinXml:Fast = s.toXML();
			gfxXml.addChild(skinXml.x);
		}
		
		return xml;
	}
	
	public function fromXML(xml:Fast):Void {
		xml = xml.node.graphic;
		
		name = U.xml_str(xml.x, "name", true);
		
		_skinsFromXML(xml);
		getColorsFromXML(xml);
		getAnimsFromXML(xml);
		_facingsFromXML(xml);
	}
	
	
	function _facingsFromXML(xml:Fast):Void
	{
		facings = [];
		if (xml.hasNode.facing)
		{
			for (facingNode in xml.nodes.facing)
			{
				var values:String = U.xml_str(facingNode.x, "value");
				if (values != "")
				{
					var valueArr:Array<String> = values.split(",");
					if (valueArr != null && valueArr.length > 1)
					{
						for (valueStr in valueArr)
						{
							var facing:Facing = Facing.fromStr(valueStr);
							facings.push(facing);
						}
					}
				}
				var defaultValue:String = U.xml_str(facingNode.x, "default");
				defaultFacing = Facing.fromStr(defaultValue);
			}
		}
	}
	
	function isPlatform(name:String):Bool
	{
		switch(name)
		{
			case "windows":
				#if windows
				return true;
				#end
			case "mac":
				#if mac
				return true;
				#end
			case "linux":
				#if linux
				return true;
				#end
			case "ps4":
				#if (ps4 || simulate == "ps4")
				return true;
				#end
			case "vita":
				#if (vita || simulate == "vita")
				return true;
				#end
			case "xbox1":
				#if (xbox1 || simulate == "xbox1")
				return true;
				#end
			case "sys":
				#if sys
				return true;
				#end
			case "flash":
				#if flash
				return true;
				#end
			case "html5":
				#if html5
				return true;
				#end
			case "web":
				#if web
				return true;
				#end
		}
		return false;
	}
	
	function platformCheck(skinNode:Fast):Bool
	{
		//Check platform compatibility per skin
		if (skinNode.hasNode.platform)
		{
			for (platformNode in skinNode.nodes.platform)
			{
				var pName = U.xml_str(platformNode.x, "name");
				if (!isPlatform(pName))
				{
					return false;
				}
			}
		}
		return true;
	}
	
	/**
	 * Load all the skin information from the xml
	 * @param	xml
	 */
	
	function _skinsFromXML(xml:Fast):Void {
		if (xml.hasNode.skin) 
		{
			var firstSkin:String = "";
			
			if (map_skins == null) 
			{
				map_skins = new Map<String,EntitySkin>();
			}
			
			var count_default:Int = 0;
			
			for (skinNode in xml.nodes.skin)
			{
				if (!platformCheck(skinNode))
				{
					continue;
				}
				
				//Get all the basic properties
				
				var sName = U.xml_str(skinNode.x, "name", true);
				if (firstSkin == "") { 
					firstSkin = sName;
				}
				
				var sAsset_src = U.xml_str(skinNode.x, "asset_src");
				var sAsset_meta = U.xml_str(skinNode.x, "asset_meta");
				var sPath= U.xml_str(skinNode.x, "path");
				var sWidth = U.xml_i(skinNode.x, "width");
				var sHeight= U.xml_i(skinNode.x, "height");
				var sOff_x = U.xml_i(skinNode.x, "off_x");
				var sOff_y = U.xml_i(skinNode.x, "off_y");
				var sIsDefault = U.xml_bool(skinNode.x, "default", false);
				
				//Check if this is the default skin
				if (sIsDefault) 
				{
					if (count_default == 0)
					{
						count_default++;
					}
					else 
					{
						sIsDefault = false;		//can't be more than one default! Ignore all "default" skins after 1st one set to default
					}
				}
				
				//Make the skin object
				var s:EntitySkin = new EntitySkin();
				s.name = sName;
				s.path = sPath;
				s.width = sWidth;
				s.height = sHeight;
				s.off_x = sOff_x;
				s.off_y = sOff_y;
				s.color_change_mode = COLOR_CHANGE_NONE;
				s.isDefault = sIsDefault;
				s.asset_src = sAsset_src;
				s.asset_meta = sAsset_meta;
				
				//Add the layer color structure if it exists
				if (skinNode.hasNode.colors && skinNode.node.colors.hasNode.layer) 
				{
					s.list_color_layers = [];
					s.list_colors = [];
					
					//Loop through the layer nodes
					for (layerNode in skinNode.node.colors.nodes.layer) 
					{
						var lName = U.xml_str(layerNode.x, "name", true, "");
						var lValue = U.parseHex(U.xml_str(layerNode.x, "value", true, "0xffffffff"), true, true, 0x00000000);
						var lAssetSrc = U.xml_str(layerNode.x, "asset_src");
						var lAssetMeta = U.xml_str(layerNode.x, "asset_meta");
						var lAlpha = U.xml_f(layerNode.x, "alpha", 1);
						var lSort = U.xml_i(layerNode.x, "sort", 0);
						
						//Create each color layer object
						var ecl = new EntityColorLayer();
						ecl.name = lName;
						ecl.asset_src = lAssetSrc;
						ecl.asset_meta = lAssetMeta;
						ecl.alpha = lAlpha;
						ecl.sort = lSort;
						
						//Add the color layer to the skin
						s.list_color_layers.push(ecl);
					}
					
					//Sort them correctly
					s.list_color_layers.sort(sortEntityColorLayers);
				}
				
				//Store the skin
				map_skins.set(sName, s);
			}
			
			//if no defaults are set, the first one is default
			if (count_default == 0)
			{
				for (key in map_skins.keys()) 
				{
					var skin:EntitySkin = map_skins.get(key);
					skin.isDefault = true;
					skinName = skin.name;
					break;
				}
			}
			
			//failsafe
			if (skinName == "")
			{
				skinName = firstSkin;
			}
		}
	}
	
	function hasMetaAttr(frameNode:Fast):Bool {
		for (attr in frameNode.x.attributes())
		{
			switch(attr) {
				case "width", "height": return true;
			}
		}
		return false;
	}
	
	function sortEntityColorLayers(a:EntityColorLayer, b:EntityColorLayer):Int {
		if (a.sort < b.sort) return -1;
		if (a.sort > b.sort) return 1;
		return 0;
	}
	
	public function getAnimsFromXML(xml:Fast):Void
	{
		animations = new Map<String,AnimationData>();
		
		if (xml.hasNode.anim) {
			for (animNode in xml.nodes.anim) {
				var a:AnimationData = new AnimationData();
				a.name = U.xml_str(animNode.x, "name");
				if (a.name == "")
				{
					a.name = U.xml_str(animNode.x, "id");
				}
				if (a.name == "")
				{
					a.name = "default";			//if no name is given the animation name is "default"
				}
				a.looped = U.xml_bool(animNode.x, "looped") || U.xml_bool(animNode.x,"loop");
				a.frameRate = U.xml_i(animNode.x, "framerate");
				a.flipX = U.xml_bool(animNode.x, "flipX");
				a.flipY = U.xml_bool(animNode.x, "flipY");
				if (animNode.hasNode.frame) {
					var i:Int = 0;
					for (frameNode in animNode.nodes.frame)
					{
						var frame:Int = U.xml_i(frameNode.x, "value", -1);
						if(frame != -1){
							a.frames.push(frame);
						}else{
							var frame_s:String = U.xml_str(frameNode.x, "range", true, "");
							if (frame_s != "" && frame_s.indexOf("-") != -1) {
								var arr:Array<String> = frame_s.split("-");
								var lo:Int = Std.parseInt(arr[0]);
								var hi:Int = Std.parseInt(arr[1]);
								for (fi in lo...hi+1) {
									a.frames.push(fi);
								}
							}
						}
						var sweet:String = U.xml_str(frameNode.x, "sweet", true);
						if (sweet != "")
						{
							var s_name:String = sweet;
							if (sweet.toLowerCase() == "true")
							{
								s_name = U.xml_str(frameNode.x, "name");
							}
							var s_x:Float = U.xml_f(frameNode.x, "x", 0);
							var s_y:Float = U.xml_f(frameNode.x, "y", 0);
							
							var sweet:AnimSweetSpot = null;
							
							if (hasMetaAttr(frameNode))
							{
								var meta:Map<String,Dynamic> = new Map<String,Dynamic>();
								for (attr in frameNode.x.attributes())
								{
									var value:String = U.xml_str(frameNode.x, attr);
									if (value != null && value != "")
									{
										switch(attr)
										{
											case "width", "height": meta.set(attr, Std.parseInt(value));
										}
									}
								}
								sweet = new AnimSweetSpot(s_name, s_x, s_y);
							}else {
								sweet = new AnimSweetSpot(s_name, s_x, s_y);
							}
							
							a.setSweetSpot(i, sweet);
						}
						
						if(frame != -1){
							i++;
						}
					}
				}
				if (animNode.hasNode.sweet) {
					for (sweetNode in animNode.nodes.sweet) {
						var s_frame:Int = U.xml_i(sweetNode.x, "value");
						
					}
				}
				animations.set(a.name, a);
			}
		}
	}
	
	function getColorChangeModeFromString(mode:String):Int
	{
		var i:Int = -1;
		if (mode == "layers" || mode == "layers_baked" || mode == "baked") {
			i = COLOR_CHANGE_LAYERS_BAKED;
		}else if (mode == "pixels") {
			i = COLOR_CHANGE_PIXEL_PALETTE;
		}else if (mode == "stacked" || mode == "layers_stacked") {
			i = COLOR_CHANGE_LAYERS_STACKED;
		}else if (mode.indexOf("custom=") != -1){
			i = COLOR_CHANGE_CUSTOM;
		}else {
			i = COLOR_CHANGE_NONE;
		}
		return i;
	}
	
	function getCustomColorModeFromString(mode:String):String
	{
		if (mode.indexOf("custom=") != -1)
		{
			return StringTools.replace(mode, "custom=", "");
		}
		return "";
	}
	
	function getColorsFromXMLWork(s:EntitySkin, skinNode:Fast):Void
	{
		if (s.color_change_mode == COLOR_CHANGE_LAYERS_BAKED || s.color_change_mode == COLOR_CHANGE_LAYERS_STACKED)
		{
			var use_default:Bool = U.xml_bool(skinNode.node.colors.x, "use_default");
			
			var copySkin:EntitySkin = null;
			
			if (use_default)
			{
				s.using_default_structure = true;
				//if it wants to use default layer structure, 
				//grab & copy that from the default skin
				copySkin = getDefaultSkin();
			}
			
			var use_structure:String = U.xml_str(skinNode.node.colors.x, "use_structure");
			if (use_structure != "")
			{
				s.using_structure = use_structure;
				copySkin = map_skins.get(use_structure);
			}
			
			if (copySkin != null && copySkin.list_color_layers != null)
			{
				s.list_color_layers = [];
				for (ecl in copySkin.list_color_layers) {
					s.list_color_layers.push(copyEntityColorLayer(ecl));
				}
			}
		}
		else if (s.color_change_mode == COLOR_CHANGE_PIXEL_PALETTE)
		{
			//Temporarily load the image
			//Scan the first vertical column in the first frame for palette information
			
			skinName = s.name;
			
			s.list_original_pixel_colors = peekPixelPalette();
		}
		
		//If color data is supplied in the skin
		if (skinNode.node.colors.hasNode.color) 
		{
			s.list_colors = [];
			
			//Loop through the color nodes
			for (colorNode in skinNode.node.colors.nodes.color) 
			{
				//Get color value
				var lValue = U.parseHex(U.xml_str(colorNode.x, "value", true, "0xffffffff"), true, true, 0x00000000);
				var index = U.xml_i(colorNode.x, "index", -1);
				
				var insert:Int = -1;
				
				if (index != -1) {
					insert = index;
				}
				
				if (s.color_change_mode == COLOR_CHANGE_LAYERS_BAKED || s.color_change_mode == COLOR_CHANGE_LAYERS_STACKED) 
				{
					//Get name value too
					var lName = U.xml_str(colorNode.x, "name", true, "");
					
					var i:Int = 0;
					
					//If a name is specified, try to match it to a color layer
					if (lName != "") 
					{
						if (s.list_color_layers != null) 
						{
							for (colorLayer in s.list_color_layers) 
							{
								if (colorLayer.name == lName) 
								{
									insert = i;
									break;
								}
								i++;
							}
						}
					}
					
					//Still can't find an insertion point? Default to the index value if it exists
					if (insert == -1 && index != -1) {
						insert = index;
					}
				}
				
				if (insert == -1) 						//no layer name was specified; just add the color in the order you found it
				{
					s.list_colors.push(lValue);
				}
				else									//a layer name was found and matched; add the color at this exact index
				{
					s.list_colors[insert] = lValue;
				}
			}
		}
	}
	
	/**
	 * Load all the color information for each skin from the xml
	 * @param	xml
	 */
	
	public function getColorsFromXML(xml:Fast):Void 
	{
		if (xml.hasNode.skin) 
		{
			for (skinNode in xml.nodes.skin)
			{
				if (!platformCheck(skinNode)) 
				{
					continue;
				}
				
				var sName:String = U.xml_str(skinNode.x, "name");
				var s:EntitySkin = map_skins.get(sName);
				
				if (skinNode.hasNode.colors) 
				{
					//Determine the color change mode of this skin
					var mode:String = U.xml_str(skinNode.node.colors.x, "mode", true);
					s.color_change_mode = getColorChangeModeFromString(mode);	
					if (s.color_change_mode == COLOR_CHANGE_CUSTOM){
						s.custom_color_change_mode = getCustomColorModeFromString(mode);
					}
					
					getColorsFromXMLWork(s,skinNode);
					
					#if neko
						if (s.list_colors != null) {
							for (i in 0...s.list_colors.length) {
								if (s.list_colors[i] == null) {
									s.list_colors[i] = 0;
								}
							}
						}
					#end
					
					if (skinNode.node.colors.hasNode.feature)
					{
						//Create color feature structure if it exists
						s.list_color_features = [];
						
						for (featureNode in skinNode.node.colors.nodes.feature) 
						{
							var featName:String = U.xml_str(featureNode.x, "name", true);
							var featPalette:String = U.xml_str(featureNode.x, "palette", true);
							var colorList:Array<Int> = [];
							for (i in 0...16) {
								var str:String = U.xml_str(featureNode.x, "c" + i);
								if (str != "") {
									var cStr:Int = Std.parseInt(str);
									colorList.push(cStr);
								}
							}
							var feature:ColorFeature = new ColorFeature(featName, colorList, featPalette);
							s.list_color_features.push(feature);
						}
					}else {
						//Otherwise, check to see if it's using the default setup
						var use_default:Bool = U.xml_bool(skinNode.node.colors.x, "use_default");
						
						var copySkin:EntitySkin = null;
						
						if (use_default) {
							//if it wants to use default feature structure, 
							//grab & copy that from the default skin
							copySkin = getDefaultSkin();
						}
						
						var use_structure:String = U.xml_str(skinNode.node.colors.x, "use_structure");
						if (use_structure != "")
						{
							s.using_structure = use_structure;
							copySkin = map_skins.get(use_structure);
						}
						
						if (copySkin != null && copySkin.list_color_features != null)
						{
							s.list_color_features = [];
							var colorFeature:ColorFeature;
							for (colorFeature in copySkin.list_color_features) 
							{
								if (colorFeature != null) {
									var colorFeatureCopy:ColorFeature = colorFeature.copy();
									s.list_color_features.push(colorFeatureCopy);
								}
							}
						}
					}
				}
			}
		}
	}
	
	/**
	 * Scan the first vertical column of the source asset for pixel palette information, return as an array
	 * @return
	 */
	
	public function peekPixelPalette():Array<FlxColor>
	{
		var arr:Array<FlxColor> = [];
		var b:BitmapData = null;
		#if sys
			if (remotePath != null && remotePath != "")
			{
				if (FileSystem.exists(remotePath + asset_src + ".png"))
				{
					#if (lime_legacy || hybrid)
						b = BitmapData.load(remotePath + asset_src + ".png");
					#else
						b = BitmapData.fromFile(remotePath + asset_src + ".png");
					#end
				}
			}
		#end
		
		var skipCache = false;
		if (b == null)
		{
			var asset = U.gfx(asset_src);
			if (FlxG.bitmap.checkCache(asset)){
				b = FlxG.bitmap.get(asset).bitmap;
			}
			else if (Assets.exists(asset))
			{
				b = Assets.getBitmapData(asset, false);	//don't cache it, just peek at it
				skipCache = true;
			}
		}
		
		if (b != null)
		{
			for (py in 0...b.height)
			{
				var pix_color:FlxColor = b.getPixel32(0, py);
				if (pix_color.alpha == 0)	//break on first 100% transparent pixel
				{
					break;
				}
				arr.push(pix_color);
			}
			
			if(skipCache){
				//destroy bitmap data information (it's safe b/c we didn't cache it!)
				b.dispose();
				b = null;
			}
		}
		
		return arr;
	}
	
	public static function getColorTransform(?Trans:ColorTransform=null,Color:FlxColor=0xffffff,Alpha:Float=1):ColorTransform {
		if (Trans == null) {
			Trans = new ColorTransform();
		}
		Trans.redMultiplier = Color.redFloat / 255;
		Trans.greenMultiplier =  Color.greenFloat / 255;
		Trans.blueMultiplier = Color.blueFloat / 255;
		Trans.alphaMultiplier = Alpha;
		return Trans;
	}
	
	public static inline function copyEntityColorLayer(ecl:EntityColorLayer):EntityColorLayer 
	{
		return ecl.copy();
	}
}

class EntityColorLayer
{
	public var name:String;			//the user-facing name (or localization flag) of this color value, "Hair", "Pants"
	public var asset_src:String;	//mask asset filename sans extension
	public var asset_meta:String;
	public var alpha:Float;			//alpha value between 1 and 0
	public var sort:Int;			//sorting index
	
	public function new(){}
	
	public inline function copy():EntityColorLayer
	{
		var copy:EntityColorLayer = new EntityColorLayer();
		copy.name = name;
		copy.asset_src = asset_src;
		copy.asset_meta = asset_meta;
		copy.alpha = alpha;
		copy.sort = sort;
		return copy;
	}
}