package io.github.stefnotch.tos;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.entity.Slime;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityDamageByEntityEvent;
import org.bukkit.event.entity.EntityDamageEvent;
import org.bukkit.metadata.FixedMetadataValue;

public class TOSPunch implements Listener {
	public TOSPunch() {
	}

	@EventHandler
	public void onEntityDamage(EntityDamageEvent e) {
		if (e instanceof EntityDamageByEntityEvent) {
			EntityDamageByEntityEvent event = (EntityDamageByEntityEvent) e;
			if (event.getDamager() instanceof Player) {
				if (event.getEntity() instanceof Slime) {
					// Damage is 0 and slime survives, needs a double
					event.setDamage(0.0);
					e.setDamage(0.0);
					// Here we get the slime and player
					Player player = (Player) event.getDamager();
					Slime slime = (Slime) event.getEntity();
					// If the slime is "owned" by the player...
					if (slime.getMetadata("Player").get(0).asString().equals(player.getName())) {
						String slimeName = slime.getMetadata("Name").get(0).asString();
						Bukkit.getServer().broadcastMessage(player.getName() + " clicked " + slimeName);
						// Bukkit.getServer().broadcastMessage("Which, of course is correct! XD");
						// TODO
						for (Entity entity : slime.getNearbyEntities(0, 1, 0)) {
							if (entity instanceof ArmorStand) {
								// If entity has metadata c
								if (entity.hasMetadata("c")) {
									// What is the player's action?
									boolean pAction = TOS.TOSGetMetadata(player, "button").asBoolean();
									//button Change
									player.setMetadata("button", new FixedMetadataValue(TOS.getInstance(),!pAction));
									// int c = TOS.TOSGetMetadata((Entity) player, "trial").asInt();
									/*
									 * if (pAction) { player.setMetadata("trial", new FixedMetadataValue(TOS.getInstance(), c - 1)); } else {
									 * player.setMetadata("trial", new FixedMetadataValue(TOS.getInstance(), c + 1)); }
									 */
									
									// Loop through all to update counter and update the name
									for (Entity entityA : Bukkit.getWorlds().get(0).getEntities()) {
										// Does this one have the metadata c too?
										if (entityA.hasMetadata("c")) {
											// Get c
											int c = entityA.getMetadata("c").get(0).asInt();
											// The name of the entity
											String entityAPreviousName = entityA.getCustomName();
											// Add 1 to it
											if (pAction) {
												// Change metadata
												entityA.setMetadata("c", new FixedMetadataValue(TOS.getInstance(), c - 1));
												c-=1;
												// Update custom name/counter
												String entityAName = entityAPreviousName.substring(0, entityAPreviousName.lastIndexOf(":") + 1) + " "
														+ c;
												entityA.setCustomName(entityAName);
											} else {
												// Change metadata
												entityA.setMetadata("c", new FixedMetadataValue(TOS.getInstance(), c + 1));
												c+=1;
												// Update custom name/counter
												String entityAName = entityAPreviousName.substring(0, entityAPreviousName.lastIndexOf(":") + 1) + " "
														+ c;
												entityA.setCustomName(entityAName);
											}
										}
									}
								}
								// Get the ArmorStand and change his name! (Bold)
								final ArmorStand a = (ArmorStand) entity;
								final String name = a.getCustomName();
								a.setCustomName(ChatColor.BOLD + name);
								Bukkit.getServer().getScheduler().scheduleSyncDelayedTask(TOS.getInstance(), new Runnable() {
									public void run() {
										a.setCustomName(name);
									}
								}, 5);
								// If the nearby entity is an armor stand, no more need to keep looping..
								break;
							}
						}
					}
				} else {
					// TODO Can not punch?

				}
			}
		}
	}
}
