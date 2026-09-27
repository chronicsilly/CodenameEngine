package funkin.editors.ui;

import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class UIImageList extends UIButtonList<UIImageButton> {
	public var imgPath:String;

	public function new(x:Int, y:Int, path:String = "images/characters", ?onImage:()-> Void){
		this.imgPath = path;

		super(x, y, 640, 270, null, FlxPoint.get(Std.int(500-16-32-20), 100), null, FlxPoint.get(-100, 0));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');
		alpha = 0.7;

		this.addButton.callback = function() {
			var butt = new UIImageButton(10, 10, 650 - 20, 60 - 10, path);
			
			if(onImage != null)
				butt.onImage = onImage;
			
			add(butt);
		}
	}

	public function getSaveDatas() {
		var data:Array<ImageSaveData> = [];

		for(b in buttons){
			var file = b.imageExplorer.getSaveData();

			if(file.imageName != null)
				data.push(file);
		}
		
		return data;
	}

	public function getAnimList():Array<String> {
		var anims:Array<String> = [];

		for(b in buttons)
			if (b.imageExplorer.animationList != null)
				anims = anims.concat(b.imageExplorer.animationList);
		
		return anims;
	}
}

class UIImageButton extends UIButton {
	public var onImage:()-> Void = null;

	public var imageExplorer:UIImageExplorer;

	public var labels:Map<UISprite, UIText> = [];

	public function new(x:Int, y:Int, w:Int, h:Int, path:String) {
		super(x,y,"",null,w,h);

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y-18, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		alpha = 0.2;

		autoAlpha = autoFrames = autoFollow = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		field.fieldWidth = 0; framesOffset = 9;
		field.size = 14;

		imageExplorer = new UIImageExplorer(10, 10, null, this.bWidth - 10, this.bHeight - 10, (_,_) -> {onImage();}, path);
		members.push(imageExplorer);
		imageExplorer.maxSize.x = w - 40;
	}

	inline function updateButtonsPos(){
		imageExplorer.follow(this, bWidth / 2 - imageExplorer.bWidth / 2, 5);

		bHeight = imageExplorer.bHeight + 10;
	}

	public override function draw() {
		updateButtonsPos();
		super.draw();
	}

	function onLoadImage(){
	}
}