package io.github.stefnotch.tos;

import org.bukkit.Bukkit;
import org.bukkit.World;
import org.bukkit.entity.Player;
import org.bukkit.scheduler.BukkitRunnable;

public class TOSNight extends BukkitRunnable {
	World world;
	int countdown = 25;

	public TOSNight() {
		world = TOS.getTheWorld();
		world.setTime(13000);
	}

	public void run() {
		world.setTime(world.getTime() + 400);
		if (world.getTime() == 23000) {
			// Deaths
			new TOSDead().runTaskTimer(TOS.getInstance(), 20, 100);
			this.cancel();
		}
		
		// Tell the time to everybody (Spectators???)
		for (Player player : Bukkit.getOnlinePlayers()) {
			player.setLevel(countdown);
		}
		
		// Countdown
		countdown--;
	}
}
