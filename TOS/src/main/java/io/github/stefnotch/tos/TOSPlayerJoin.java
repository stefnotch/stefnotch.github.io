package io.github.stefnotch.tos;

import net.minecraft.server.v1_8_R1.ChatSerializer;
import net.minecraft.server.v1_8_R1.EnumTitleAction;
import net.minecraft.server.v1_8_R1.IChatBaseComponent;
import net.minecraft.server.v1_8_R1.PacketPlayOutTitle;
import net.minecraft.server.v1_8_R1.PlayerConnection;

import org.bukkit.Bukkit;
import org.bukkit.craftbukkit.v1_8_R1.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerLoginEvent;

//import org.bukkit.scheduler.BukkitTask;

public class TOSPlayerJoin implements Listener {
	public TOSPlayerJoin() {
	}

	// Here the player will not be in the Bukkit getOnlinePlayers array!
	@EventHandler(priority = EventPriority.HIGHEST)
	public void beforeJoin(PlayerLoginEvent event) {
		Player player = event.getPlayer();
		if (Bukkit.getOnlinePlayers().length == TOS.pCount) {
			player.kickPlayer("You were kicked because the game is full.");
		}
	}

	// Here the player will be in the Bukkit getOnlinePlayers array!
	@EventHandler
	public void onJoin(PlayerJoinEvent event) {
		Bukkit.broadcastMessage("" + Bukkit.getOnlinePlayers()[0].getName());
		Player player = event.getPlayer();

		if (Bukkit.getOnlinePlayers().length <= TOS.pCount) {

			CraftPlayer craftplayer = (CraftPlayer) player;// Get player
			PlayerConnection connection = craftplayer.getHandle().playerConnection;// Get playerConnection

			IChatBaseComponent titleJSON = ChatSerializer.a("{'text': ' Welcome to Town of Salem '}");
			IChatBaseComponent subtitleJSON = ChatSerializer.a("{'text': ' Credits: MeowningInsanely'}");
			PacketPlayOutTitle titlePacket = new PacketPlayOutTitle(EnumTitleAction.TITLE, titleJSON, 0, 2, 0);
			PacketPlayOutTitle subtitlePacket = new PacketPlayOutTitle(EnumTitleAction.SUBTITLE, subtitleJSON);
			connection.sendPacket(titlePacket);
			connection.sendPacket(subtitlePacket);
			
			if (Bukkit.getOnlinePlayers().length == TOS.pCount) {
				//Delay, period
				//The delay is 40(2 seconds) so everybody can see the previous titles^^
				new TOSLoginCountdown().runTaskTimer(TOS.getInstance(), 40, 40);
			}
			/*
			 * for (int i = 0; i < TOS.playerArray.length; i++) { if (TOS.playerArray[i][0] == null) { TOS.playerArray[i][0] = player.getName(); if (i
			 * == TOS.playerArray.length - 1) {// Change to 6 new TOSLoginCountdown().runTaskTimer(TOS.getInstance(), 20, 40); } break; } }
			 */
		}
	}
}
