package funkin.editors.stage;

typedef StageCreationData = {
	var name:String;
	var path:String;
}

class StageCreationScreen extends UISubstateWindow {
	private var onSave:Null<StageCreationData> -> Void = null;

	public var stageNameTextBox:UITextBox;
	public var stagePathTextBox:UITextBox;
	public var voicesExplorer:UIFileExplorer;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public function new(?onSave:StageCreationData->Void) {
		super();
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = "Creating New Stage";

		winWidth = 748 - 32 + 40;
		winHeight = 220;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		var stageInfo:UIText;
		add(stageInfo = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Stage Info", 28));

		add(stageNameTextBox = new UITextBox(stageInfo.x, stageInfo.y + stageInfo.height + 36, "Stage Name"));
		addLabelOn(stageNameTextBox, "Stage Name");

		add(stagePathTextBox = new UITextBox(stageNameTextBox.x + 320 + 26, stageNameTextBox.y, "Stage Path"));
		addLabelOn(stagePathTextBox, "Stage Path");

		add(saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveStageInfo();
			close();
		}, 125));

		add(closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, "Cancel", close, 125));
		closeButton.color = 0xFFFF0000;
	}

	function saveStageInfo() {
		if (onSave != null) onSave({
			name: stageNameTextBox.label.text,
			path: stagePathTextBox.label.text
		});
	}

}