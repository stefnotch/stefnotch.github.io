package io.github.stefnotch.tos;

import java.util.ArrayList;
import java.util.Random;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.meta.BookMeta;
import org.bukkit.metadata.FixedMetadataValue;
import org.bukkit.metadata.MetadataValue;
import org.bukkit.plugin.Plugin;
import org.bukkit.plugin.java.JavaPlugin;



public class TOS extends JavaPlugin {
	// Role, Visible to, Alive/Dead/Grave, Killer, cButtonClick: boolean, onTrial (Counter)
	// role, visible, a, killer, button, trial
	// player.canSee(player);
	// onTrial: counter first it will count the votes, if votes > player count, reset all counts except the one of the dude on trial!
	// Player count
	public static int pCount = 1;
	public static String[] graveyard = new String[1];// CHANGE TO 7
	// All lowercase! Stores in what phase the server is, lobby, dead, discussion, vote, defense, trial, last, night
	public static String phase = "lobby";
	private static TOS tos;
	private static World w;
	static Random random = new Random();
	
	@Override
	public void onEnable() {
		tos = this;
		w = getServer().getWorlds().get(0);
		getServer().getPluginManager().registerEvents(new TOSPlayerJoin(), this);
		getServer().getPluginManager().registerEvents(new TOSPunch(), this);
		getServer().getPluginManager().registerEvents(new TOSCommandListener(), this);

		// server.dispatchCommand(server.getConsoleSender(), "sm 1");

	}

	@Override
	public void onDisable() {

	}
	
	
	@Override
	public boolean onCommand(CommandSender sender, Command cmd, String label, String[] args) {
		// If the player typed basic...
		if (cmd.getName().equalsIgnoreCase("basic")) {
			// Player player = (Player) sender;
			return true;
		}
		// Whisper
		if (cmd.getName().equalsIgnoreCase("whisper")) {
			// Is the sender a player
			if (sender instanceof Player) {
				// Is the argument length correct
				if (args.length >= 2) {
					Player target = (Bukkit.getServer().getPlayer(args[0]));
					if (target == null) {
						sender.sendMessage(args[0] + " is not online!");
						return false;
					} else {
						Bukkit.getServer().broadcastMessage(sender.getName() + " wispers to " + target.getName());
						String msg = args[1];
						for (int i = 2; i < args.length; i++) {
							msg += " " + args[i];
						}
						target.sendMessage(msg);
					}
				} else {
					sender.sendMessage(ChatColor.RED + "2 arguments are needed!");
					return false;
				}
			} else {
				sender.sendMessage("You must be a player.");
				return false;
			}
			return true;
		}
		return false;
	}

	// Game started
	public static void theGameHasStarted() {
		Bukkit.getServer().broadcastMessage("The game has started...");
		// Stops the sun from moving
		Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "gamerule doDaylightCycle false");
		// All possible roles
		// \n doesn't work
		// TODO Framer(Make shorter?), Jailor(Make shorter?), GF(Make 1 line shorter?),
		String[][] roleList = {
				{ "Sheriff", "§aTown §r(§9Investigative§r)", "§6Abilities:", "-Check one person each night for suspicious activity.",
						"§6Attributes:", "-You will know if your target is a member of the Mafia, except for the Godfather.",
						"-You will know if your target is a Serial Killer.", "§6Goal:", "-Lynch every criminal and evildoer." },
				{ "Doctor", "§aTown §r(§9Protective§r)", "§6Abilities:", "-Heal one person each night, preventing them from dying.", "§6Attributes:",
						"-You may only heal yourself once.", "-You will know if your target is attacked.", "§6Goal:",
						"-Lynch every criminal and evildoer." },
				{ "Investigator", "§aTown §r(§9Investigative§r)", "§6Abilities:", "-Investigate one person each night for a clue to their role.",
						"§6Attributes:", "-None", "§6Goal:", "-Lynch every criminal and evildoer." },
				{ "Jailor", "Town §r(§9Killing§r)", "§6Abilities:", "-You may choose one person during the day to jail for the night.",
						"§6Attributes:", "-You may anonymously talk with your prisoner.", "-You may execute your prisoner.",
						"-The jailed target cannot use their night ability.", "-While jailed, the prisoner is night immune.", "§6Goal:",
						"-Lynch every criminal and evildoer." },
				{ "Medium", "Town §r(§9Support§r)", "§6Abilities:", "-Speak with a dead person at night.", "§6Attributes:",
						"-You will speak to your target anonymously.", "§6Goal:", "-Lynch every criminal and evildoer." },
				{ "Escort", "Town §r(§9Support§r)", "§6Abilities:", "-Distract someone each night.", "§6Attributes:",
						"-Distraction stops your target from using their night ability.", "-You are immune to role blocks.",
						"-If you target a Serial Killer they will attack you.", "§6Goal:", "-Lynch every criminal and evildoer." },
				{ "Lookout", "Town §r(§9Investigative§r)", "§6Abilities:", "-Watch one person at night to see who visits them.", "§6Attributes:",
						"-None.", "§6Goal:", "-Lynch every criminal and evildoer." },
				{ "Godfather", "§4Mafia §r(§9Killing§r)", "§6Abilities:", "-Kill someone each night.", "§6Attributes:",
						"-You can't be killed at night.", "-If there is a Mafioso, he will attack the target instead of you.",
						"-You will appear to be a town member to the Sheriff.", "-You can talk with the other Mafia at night.", "§6Goal:",
						"-Kill anyone that will not submit to the Mafia." },
				{ "Framer", "§4Mafia §r(§9Deception§r)", "§6Abilities:", "-Choose one person to frame each night.", "§6Attributes:",
						"-If your target is investigated they will appear to be a Mafia member.",
						"-If there are no kill capable Mafia roles left you will become a Mafioso.", "-You can talk with the other Mafia at night.",
						"§6Goal:", "-Kill anyone that will not submit to the Mafia." },
				{ "Mafioso", "§4Mafia §r(§9Killing§r)", "§6Abilities:", "-Carry out the Godfather's orders.", "§6Attributes:",
						"-You can kill if the Godfather doesn't give you orders.", "-If the Godfather dies you will become the next Godfather.",
						"-You can talk with the other Mafia at night.", "§6Goal:", "-Kill anyone that will not submit to the Mafia." },
				{ "Executioner", "§bNeutral §r(§9Evil§r)", "§6Abilities:", "-Trick the Town into lynching your target.", "§6Attributes:",
						"-If your target is killed at night you will become a Jester.", "-Your target is ", "§6Goal:",
						"-Get your target lynched at any cost." },
				{ "Serial Killer", "§bNeutral §r(§9Killing§r)", "§6Abilities:", "-Kill someone each night.", "§6Attributes:",
						"-If you are role blocked you will attack the role blocker instead of your target.", "-You can not be killed at night.",
						"§6Goal:", "-Kill everyone who would oppose you." },
				{ "Jester", "§bNeutral §r(§9Evil§r)", "§6Abilities:", "-Trick the Town into voting against you.", "§6Attributes:",
						"-If you are lynched you may kill one of your guilty voters the following night.", "§6Goal:",
						"-Get yourself lynched by any means necessary." }, { "Town Killing" }, { "Random Town" } };
		// Shuffle the array of roles
		for (int i = 0; i < roleList.length; i++) {
			int randomPosition = random.nextInt(roleList.length);
			// If it is an Executioner
			if (roleList[i][0].equals("Executioner")) {
				// Change the roleList
				roleList[i][6] = "-Your target is " + Bukkit.getOnlinePlayers()[random.nextInt(pCount)];
			}
			// Temporary storage
			String[] temp = roleList[i];
			roleList[i] = roleList[randomPosition];
			roleList[randomPosition] = temp;
		}
		// Loop through the players
		for (int i = 0; i < Bukkit.getOnlinePlayers().length; i++) {
			Player player = Bukkit.getOnlinePlayers()[i];
			// Assign role
			player.setMetadata("role", new FixedMetadataValue(tos, roleList[i][0]));
			// Make the players alive
			player.setMetadata("a", new FixedMetadataValue(tos, "Alive"));
			// The player didn't click a button so far...
			player.setMetadata("button", new FixedMetadataValue(tos, false));
			// The player isn't on trial
			player.setMetadata("trial", new FixedMetadataValue(tos, 0));
			// Clear inventory
			player.getInventory().clear();
			// Add a watch to the inventory
			player.getInventory().addItem(new ItemStack(Material.WATCH, 1));

			// The page
			String page = "";
			// Pages ArrayList
			ArrayList<String> pages = new ArrayList<String>();

			// Explain the role
			for (int ii = 0; ii < roleList[i].length; ii++) {
				player.sendMessage(roleList[i][ii]);
				if (roleList[i][ii].equals("§6Attributes:")) {
					page += "\n§oGo to the next page!";
					pages.add(page);
					page = "§6Attributes:\n";
				} else if (roleList[i][ii].equals("§6Goal:")) {
					page += "\n§oGo to the next page!";
					pages.add(page);
					page = "§6Goal:\n";
				} else {
					page += "§r" + roleList[i][ii] + "\n";
				}
			}
			pages.add(page);
			// Written book with role
			ItemStack book = new ItemStack(Material.WRITTEN_BOOK);

			BookMeta bookMeta = (BookMeta) book.getItemMeta();
			bookMeta.setTitle(ChatColor.RED + "Your Role!");
			bookMeta.setAuthor(ChatColor.GRAY + "Stefnotch");
			// Book pages
			bookMeta.setPages(pages);

			book.setItemMeta(bookMeta);
			player.getInventory().addItem(book);
			// MY PREVIOUS FAIL:
			/*
			 * // NMS book net.minecraft.server.v1_8_R1.ItemStack bookItem = CraftItemStack.asNMSCopy(new ItemStack(Material.WRITTEN_BOOK)); //
			 * NBTCompound NBTTagCompound nbtBook = new NBTTagCompound(); nbtBook.setString("title", "Your Role!"); nbtBook.setString("author",
			 * "Stefnotch");
			 * 
			 * NBTTagCompound nbtCompoundToList = new NBTTagCompound(); nbtCompoundToList.setString("1", "x");
			 * 
			 * NBTTagList list = new NBTTagList(); list.add(nbtCompoundToList); // nbttaglist.add(new NBTTagString("page1", "This is page 1")); //
			 * nbttaglist.add(new NBTTagString("page2", "This is page 2")); // nbttaglist.add(new NBTTagString("page3", "This is page 3"));
			 * 
			 * nbtBook.set("pages", list); // Set the compound to the NMS book bookItem.setTag(nbtBook); // GIVE HIM THE BOOK player.getInventory
			 * ().addItem(CraftItemStack.asCraftMirror(bookItem));
			 */
	
		}

		// 20 = delay, 20 = delay between calls
		// Use Nina's awesome XP bar idea/use an custom named enderdragon
		new TOSDay().runTaskTimer(tos, 20, 20);
		// Example of a GUI
		/*
		 * String[][] guiString = { { playerArray[0][0] }, { "30", "-0.5", "Yes", "b" }, { "-30", "-0.5", "Of course", "b" },{ "0", "1.5",
		 * "Is Meow awesome?", "t" } };
		 */
	
		// TOSGUI gui = new TOSGUI(guiString);

		// TODO MAIN GAME LOGIC HERE
	}

	public static Plugin getInstance() {
		return tos;
	}

	public static World getTheWorld() {
		return w;
	}

	// Metadata get
	public static MetadataValue TOSGetMetadata(Entity e, String metadata) {
		if (e.hasMetadata(metadata)) {
			return e.getMetadata(metadata).get(0);
		} else {
			return null;
		}

	}
}
