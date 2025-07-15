package funkin.editors.character;

class CharacterCreationScreen extends UISubstateWindow {
	public function new() {
		super();
	}

	public override function create() {
		winTitle = "Creating New Character";

		winWidth = 748 - 32 + 40;
		winHeight = 520;

		super.create();

		var textBox:UITextBox = new UITextBox(30, 130, "");
		add(textBox);

		add(new UIText(textBox.x, textBox.y - 20, textBox.label.width, "Your character's image file name:"));

		add(new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			if (openfl.utils.Assets.exists(Paths.image('characters/' + textBox.label.text))) {
				#if sys
				CoolUtil.safeSaveFile('${Paths.getAssetsRoot()}/data/characters/${textBox.label.text}.xml', CharacterEditor.rawXML);
				#else
				openSubState(new SaveSubstate(CharacterEditor.rawXML,{defaultSaveFile: textBox.label.text + '.xml'}));
				#end

				CharacterEditor.__character = textBox.label.text;
				FlxG.switchState(new CharacterEditor(textBox.label.text));
			} else {
				openSubState(new UIWarningSubstate("Warning!", "Your character's image file doesn't exist.", [
					{
						label: "OK",
						onClick: function(t) {
							trace("OK clicked!");
						}
					}
				]));
			}
		}, 130, 32));

		var closeButton:UIButton = new UIButton(textBox.x, textBox.y + textBox.label.height + 50, "Cancel", function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		parent.persistentUpdate = false;
	}
}