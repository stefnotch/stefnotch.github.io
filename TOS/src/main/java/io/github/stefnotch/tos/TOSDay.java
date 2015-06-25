package io.github.stefnotch.tos;

import org.bukkit.Bukkit;
import org.bukkit.World;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.Player;
import org.bukkit.entity.Slime;
import org.bukkit.scheduler.BukkitRunnable;

public class TOSDay extends BukkitRunnable {
	World world;

	int countdown = 40;
	TOSGUI gui;

	public TOSDay() {
		world = TOS.getTheWorld();
		world.setTime(23000);
	}

	public void run() {
		world.setTime(world.getTime() + 140);

		// Time change (24,000 is the same as 0);
		if (world.getTime() == 24120) {
			world.setTime(120);
		}
		// Vote
		if (world.getTime() == 4600) {
			// TODO
			// TextComponent message = new TextComponent("Click me");
			// message.setClickEvent(new ClickEvent(ClickEvent.Action.OPEN_FILE,
			// "http://spigotmc.org"));
			// message.setHoverEvent(new HoverEvent(HoverEvent.Action.SHOW_TEXT,
			// new ComponentBuilder("Goto the Spigot website!").create()));
			countdown = 25;
			// WHO SHALL BE put on trial?
			String[][] guiString = { { Bukkit.getOnlinePlayers()[0].getName() }, { "30", "-0.5", "Yes", "b" }, { "-30", "-0.5", "Of course:", "c" },
					{ "0", "1.5", "Is Meow awesome?", "t" } };
			gui = new TOSGUI(guiString);
		}
		// Defense
		if (world.getTime() == 8100) {
			world.setTime(8100);
			countdown = 20;
			// TODO, check who has the highest count.
			kill();
		}
		// Judge
		if (world.getTime() == 10900) {
			countdown = 10;
			String[][] guiString = { { Bukkit.getOnlinePlayers()[0].getName() }, { "30", "-0.5", "Guilty", "b" }, { "-30", "-0.5", "Innocent", "b" },
					{ "0", "1.5", "Is he/she guilty?", "t" } };
			gui = new TOSGUI(guiString);
		}
		// Last words
		if (world.getTime() == 12300) {
			countdown = 5;
			kill();
		}
		// TODO
		// Night
		if (world.getTime() == 13000) {
			new TOSNight().runTaskTimer(TOS.getInstance(), 20, 20);
			this.cancel();
		}
		
		// Tell the time to everybody (Spectators???)
		for (Player player : Bukkit.getOnlinePlayers()) {
			player.setLevel(countdown);
		}
		// Countdown
		countdown--;
	}

	public void kill() {
		gui = null;
		for (org.bukkit.entity.Entity e : Bukkit.getWorlds().get(0).getEntities()) {
			if (e instanceof Slime & e.hasMetadata("Name")) {
				// ((EntityLiving) e).setHealth(0);
				e.remove();
			}
			if (e instanceof ArmorStand & e.getCustomName() != null) {
				// TODO Check if the name is an allowed one...
				e.remove();
			}
		}
	}
}
