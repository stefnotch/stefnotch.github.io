# Constraining to a cone\*

\*with the least amount of trigonometry

TODO: If you specify a cone angle as a vector, you could get away with zero trig

$v = \text{Vector to clamp (normalized)}$  
$u = \text{Clamping direction vector (normalized)}$  
$\alpha = \text{Clamping angle}$

Figure out what the cutoff dot product $d$ is  
$acos(dot(v, u)) = \alpha$  
$d = cos(\alpha)$

Quick test  
$\text{if}(dot(v,u) >= d) \text{ return } d$

Otherwise, we gotta clamp our vector towards u.

As a first step, we'll clamp our vector towards 90 degree/pi.

$u - u * dot(v,u)$

Now we have a simple, specialized case that we can easily reason about. The next step would be to add something to the vector so that it's inside the cone again.

TODO: Normalize it, divide by g, add u \* d

<ClientOnly>
  <Demo/>
</ClientOnly>

## Example code

```cs
// Constrains a vector to a cone around some other vector
// coneDirection should be normalized
public static Vector3 ConstrainToCone(ref Vector3 direction, ref Vector3 coneDirection, float maxAngle)
{
    if (maxAngle <= 0) return coneDirection * direction.Length;
    if (maxAngle >= Mathf.Pi) return direction;

    Vector3 unitDirection = direction.Normalized; // normalizing can sometimes be avoided (just pass in a normalized direction)

    float cutoffDotProduct = Mathf.Cos(maxAngle); // could be precomputed
    float coneRadius = Mathf.Sin(maxAngle); // could be precomputed

    float vectorDotProduct = Vector3.Dot(ref unitDirection, ref coneDirection);
    if (vectorDotProduct >= cutoffDotProduct) return direction;

    // Note: The case with the direction vector being the exact opposite of the coneDirection might need extra handling
    // Hm, is this actually correct? (direction instead of unitDirection)
    Vector3 clampedToPie = direction - coneDirection * vectorDotProduct;
    clampedToPie.Normalize();
    clampedToPie /= coneRadius;

    return clampedToPie + coneDirection * cutoffDotProduct;
}
```

<script setup>
import Demo from './ConstrainToConeDemo.vue'
</script>
