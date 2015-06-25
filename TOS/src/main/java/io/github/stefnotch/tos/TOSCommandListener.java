package io.github.stefnotch.tos;

import org.bukkit.ChatColor;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;

public class TOSCommandListener implements Listener {
	public TOSCommandListener() {
	}

	@EventHandler
	public void onCommandPreprocess(AsyncPlayerChatEvent event) {
		Player sender = event.getPlayer();
		if (event.getMessage().startsWith("/msg")|event.getMessage().startsWith("/tell")|event.getMessage().startsWith("/w")) {
			sender.sendMessage(ChatColor.RED + "This has been disabled, use /whisper instead!");
			event.setCancelled(true);
		}
		//TODO Disable chat for some players......
		//A) All not player-players/spectators
		//B) During defense/last words/TOSDead nobody except XYZ can chat
	}

}
