package io.github.stefnotch.tos;

import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.metadata.FixedMetadataValue;
import org.bukkit.scheduler.BukkitRunnable;

public class TOSDead extends BukkitRunnable {
	// The player that the plugin is displaying messages for
	Player p;
	int counter = 0;

	public TOSDead() {

	}

	public void run() {
		switch (counter) {
		case 0:
			for (Player player : Bukkit.getOnlinePlayers()) {
				if (TOS.TOSGetMetadata(player, "a").asString().equals("Dead")) {
					p = player;
					counter = 7;
					break;
				}
			}
			break;
		case 7:
			Bukkit.broadcastMessage("We found " + p.getName() + " dead in their home last night.");
			break;
		case 6:
			Bukkit.broadcastMessage("We found a will next to their body.");
			break;
		case 5: // TODO Display last will
			break;
		case 4:
			Bukkit.broadcastMessage("We found a death note next to their body.");
			break;
		case 3: // TODO Display death note
			break;
		case 2:
			Bukkit.broadcastMessage("KILLED");// TODO Creative death message
			break;
		case 1:
			Bukkit.broadcastMessage(p.getName() + "'s role was" + TOS.TOSGetMetadata(p, "role").asString());
			break;
		}
		counter--;
	}
}
