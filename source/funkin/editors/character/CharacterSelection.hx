package funkin.editors.character;

import haxe.xml.Printer;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import funkin.game.Character;
import funkin.options.OptionsScreen;
import funkin.options.type.IconOption;
import funkin.options.type.NewOption;
import funkin.options.type.TextOption;
import funkin.options.type.OptionType;
import funkin.backend.assets.ModsFolder;

class CharacterSelection extends EditorTreeMenu
{
	public var modsList:Array<String> = [];

	public override function create()
	{
		bgType = "charter";
		super.create();

		var isMods:Bool = true;
		modsList = Character.getList(true, true);

		if(modsList.length == 0) {
			modsList = Character.getList(false, true);
			isMods = false;
		}

		function generateList(modsList:Array<String>, isMods:Bool, folderPath:String = ""):Array<OptionType> {
			var list:Array<OptionType> = [];

			for(char in modsList) {
				if(char.endsWith("/")) {
					var folderName = CoolUtil.getFilename(char.substr(0, char.length-1));

					list.push(new TextOption(folderName + " >", "Press ACCEPT to edit this folder.", function() {
						var newModsList = Character.getList(isMods, true, char);
						var newList:Array<OptionType> = generateList(newModsList, isMods, folderPath + folderName + "/");
						optionsTree.add(new OptionsScreen(folderPath + folderName, "Select a character to edit in " + folderPath + folderName + "/", newList));
					}));
				} else {
					list.push(new IconOption(char, "Press ACCEPT to edit this character.", Character.getIconFromCharName(folderPath + char, char),
						function() {
							FlxG.switchState(new CharacterEditor(folderPath + char));
						})
					);
				}
			}

			list.insert(0, new NewOption("New Character", "Press ACCEPT to create a new character.", function() {
				openSubState(new CharacterCreationScreen(createCharacter));
			}));

			return list;
		}

		var list = generateList(modsList, isMods);

		main = new OptionsScreen("Character Editor", "Select a character to edit", list);

		DiscordUtil.call("onEditorTreeLoaded", ["Character Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}

	public function createCharacter(name:String, imageSaveData:ImageSaveData, xml:Xml) {
		var characterAlreadyExists:Bool = modsList.contains(name);
		if (characterAlreadyExists) {
			openSubState(new UIWarningSubstate("Creating Character: Error!", "The character you are trying to create already exists, if you would like to override it delete the character first!", [
				{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
			]));
			return;
		}

		// Save Data file
		var characterPath:String = '${Paths.getAssetsRoot()}/data/characters/${name}.xml';
		CoolUtil.safeSaveFile(characterPath, "<!DOCTYPE codename-engine-character>\n" + Printer.print(xml, true));

		// Save Image files 
		UIImageExplorer.saveFilesGlobal(imageSaveData, '${Paths.getAssetsRoot()}/images/characters');

		// Add to Menu >:D
		var option:IconOption = new IconOption(name, "Press ACCEPT to edit this character.", Character.getIconFromCharName(name),
			function() {
				FlxG.switchState(new CharacterEditor(name));
			}
		);
		optionsTree.members[optionsTree.members.length-1].insert(1, option);
	}
}