package io.github.stefnotch.tos;

import net.minecraft.server.v1_8_R1.ChatSerializer;
import net.minecraft.server.v1_8_R1.EnumTitleAction;
import net.minecraft.server.v1_8_R1.IChatBaseComponent;
import net.minecraft.server.v1_8_R1.PacketPlayOutTitle;
import net.minecraft.server.v1_8_R1.PlayerConnection;

import org.bukkit.Bukkit;
import org.bukkit.craftbukkit.v1_8_R1.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.scheduler.BukkitRunnable;

public class TOSLoginCountdown extends BukkitRunnable {

	public TOSLoginCountdown() {
	}

	int subtitle = 5;

	public void run() {
		if (subtitle == 0) {
			TOS.theGameHasStarted();
			this.cancel();

		}
		for (Player player : Bukkit.getOnlinePlayers()) {
			CraftPlayer craftplayer = (CraftPlayer) player;// Get player
			PlayerConnection connection = craftplayer.getHandle().playerConnection;// Get playerConnection

			IChatBaseComponent titleJSON = ChatSerializer.a("{'text': ' STARTING THE GAME IN: '}");
			IChatBaseComponent subtitleJSON = ChatSerializer.a("{'text': '" + subtitle + "'}");
			PacketPlayOutTitle titlePacket = new PacketPlayOutTitle(EnumTitleAction.TITLE, titleJSON, 0, 2, 0);
			PacketPlayOutTitle subtitlePacket = new PacketPlayOutTitle(EnumTitleAction.SUBTITLE, subtitleJSON);
			connection.sendPacket(titlePacket);
			connection.sendPacket(subtitlePacket);
			subtitle--;
		}
	}
	// Bukkit.getServer().getScheduler().cancelTask(scheduler);
	/*
	 * //CraftPlayer craftplayer = (CraftPlayer) player; PlayerConnection connection = craftplayer.getHandle().playerConnection; IChatBaseComponent
	 * titleJSON = ChatSerializer .a("{'text': ' STARTING THE GAME IN: '}"); // IChatBaseComponent subtitleJSON = // ChatSerializer.a("{'text': '" +
	 * subtitle + "'}"); PacketPlayOutTitle titlePacket = new PacketPlayOutTitle( EnumTitleAction.TITLE, titleJSON, 0, 5, 0); // PacketPlayOutTitle
	 * subtitlePacket = new // PacketPlayOutTitle(EnumTitleAction.SUBTITLE, // subtitleJSON); connection.sendPacket(titlePacket);
	 * TOS.theGameHasStarted(playerArray); // connection.sendPacket(subtitlePacket); // Bukkit.getServer().broadcastMessage("STARTING THE GAME!!!");
	 */
	// DO MAIN GAME LOGIC HERE!
}
