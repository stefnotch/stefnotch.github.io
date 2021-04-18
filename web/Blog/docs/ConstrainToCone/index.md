# Constraining to a cone

## With unit vectors

$v = \text{Vector to clamp}$

$u = \text{Clamping direction vector}$  
$\alpha = \text{Clamping angle}$

Figure out what the cutoff dot product $d$ is  
$acos( dot(v, u)) = \alpha$  
$d = cos(\alpha)$

Quick test  
$\text{if}(dot(v,u) < d) \text{ return } d$

Otherwise, we gotta clamp our vector towards u

<ClientOnly>
  <Demo/>
</ClientOnly>

## With arbitrary vectors

<script setup>
import Demo from './ConstrainToConeDemo.vue'
</script>
