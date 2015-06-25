package io.github.stefnotch.tos;

import net.minecraft.server.v1_8_R1.Entity;
import net.minecraft.server.v1_8_R1.EntityLiving;
import net.minecraft.server.v1_8_R1.NBTTagCompound;
import net.minecraft.server.v1_8_R1.NBTTagList;

import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.craftbukkit.v1_8_R1.entity.CraftEntity;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.Player;
import org.bukkit.entity.Slime;
import org.bukkit.metadata.FixedMetadataValue;
import org.bukkit.util.Vector;

//import org.bukkit.potion.PotionEffect;

public class TOSGUI {
	String[][] buttons;
	ArmorStand as;

	// 2D array
	// {player},{ButtonX,ButtonY,text,b/t/c},{ButtonX,ButtonY,text,b/t/c},..
	// b=button
	// t=text
	// c=counter
	public TOSGUI(String[][] b) {
		buttons = b;
		// Player
		Player player = Bukkit.getServer().getPlayer(buttons[0][0]);
		// Player eye location
		Location playerEye = player.getEyeLocation();
		playerEye.setPitch(0f);
		// The yaw of the player
		float playerYaw = playerEye.getYaw();

		// Loop through the buttons
		for (int i = 1; i < buttons.length; i++) {
			Location locInLoop = playerEye.clone();
			locInLoop.setYaw(playerYaw + (float) Integer.parseInt(buttons[i][0]));
			
			Vector addToLoc = locInLoop.getDirection().setY(0).multiply(2);
			locInLoop.add(addToLoc);
			// Now adjust the Y...
			locInLoop.add(0, Double.parseDouble(buttons[i][1]), 0);
			if (buttons[i][3].equals("t")) {
			} else {
				// Slime
				Slime slime = player.getWorld().spawn(locInLoop, Slime.class);
				// The name of the slime so we can get it later...the player
				// that clicked it will be chosen with the Entitydamage event
				slime.setMetadata("Name", new FixedMetadataValue(TOS.getInstance(), buttons[i][2]));
				// So we know the owner of the slime..
				slime.setMetadata("Player", new FixedMetadataValue(TOS.getInstance(), player.getName()));
				// CraftEntity Slime
				Entity nmsEntity0 = ((CraftEntity) slime).getHandle();
				// A map to convert to a list
				// Ambient:0b,ShowParticles:0b,Duration:199892,Id:14b,Amplifier:1b
				NBTTagCompound mapToList = new NBTTagCompound();
				mapToList.setByte("Ambient", (byte) 0);
				mapToList.setByte("ShowParticles", (byte) 0);
				mapToList.setInt("Duration", 10000);
				mapToList.setByte("Id", (byte) 14);
				mapToList.setByte("Amplifier", (byte) 1);
				// List from a map
				NBTTagList list = new NBTTagList();
				list.add(mapToList);
				//
				NBTTagCompound SlimeTag = new NBTTagCompound();
				// writes entity's nbt data to OUR tag object
				nmsEntity0.c(SlimeTag);
				SlimeTag.setBoolean("NoAI", true);
				SlimeTag.setInt("Size", 0);
				SlimeTag.set("ActiveEffects", list);
				// sets the entity's tag to OUR tag
				((EntityLiving) nmsEntity0).a(SlimeTag);
			}

			// ArmorStand(The name tag)
			as = player.getWorld().spawn(locInLoop.subtract(0, 1.2, 0), ArmorStand.class);
			as.setCustomName(buttons[i][2]);
			as.setCustomNameVisible(true);
			// meatadata
			if (buttons[i][3].equals("c")) {
				as.setMetadata("c", new FixedMetadataValue(TOS.getInstance(), 0));
			}
			NBTTagCompound ArmorTag = new NBTTagCompound();
			// ArmorStand
			Entity nmsEntity1 = ((CraftEntity) as).getHandle();

			// writes entity's nbt data to OUR tag object
			nmsEntity1.c(ArmorTag);
			ArmorTag.setByte("Invisible", (byte) 1);
			ArmorTag.setByte("Invulnerable", (byte) 1);
			ArmorTag.setByte("NoGravity", (byte) 1);
			ArmorTag.setByte("Small", (byte) 1);
			// sets the entity's tag to OUR tag
			((EntityLiving) nmsEntity1).a(ArmorTag);

		}
	}
}
