<template>
  <div ref="drawing-area"></div>
</template>

<script lang="ts">
import {
  ref,
  defineComponent,
  watchEffect,
  watch,
  computed,
  onMounted,
  nextTick,
  PropType,
} from "vue";
import Two from "two.js";

export default defineComponent({
  setup(props, context) {
    const drawingArea = ref<HTMLElement>(null);
    const scaleUpFactor = 100;

    onMounted(() => {
      let two = new Two({ width: 285, height: 210 }).appendTo(
        drawingArea.value
      );
      let mouse = new Two.Vector();

      two.renderer.domElement.addEventListener(
        "mousemove",
        (e) => mouse.set(e.offsetX - two.width / 2, e.offsetY - two.height / 2),
        false
      );

      let g = new Two.Group();
      two.add(g);

      let unitCircle = two.makeCircle(0, 0, 1 * scaleUpFactor);
      unitCircle.stroke = "black";
      g.add(unitCircle);

      let cursorCircle = two.makeCircle(0, 0, 1);
      cursorCircle.stroke = "black";
      g.add(cursorCircle);

      // TODO: make this one draggable
      // TODO: Draw text to identify the paths
      let coneArrow = two.makePath(
        0,
        0,
        1 * scaleUpFactor,
        0 * scaleUpFactor,
        true
      );
      coneArrow.stroke = "lightgreen";
      g.add(coneArrow);

      let arbitraryVector = two.makePath(
        0,
        0,
        0 * scaleUpFactor,
        1 * scaleUpFactor,
        true
      );
      console.log(arbitraryVector);
      arbitraryVector.vertices[1].x = 20;
      arbitraryVector.vertices[1].y = 20;
      arbitraryVector.stroke = "blue";
      g.add(arbitraryVector);

      let aaaa = two.makeCircle(0, 0, 2);
      g.add(aaaa);

      g.translation.set(two.width / 2, two.height / 2);
      two.render();

      two
        .bind("update", function (frameCount) {
          cursorCircle.translation.set(mouse.x, mouse.y);

          if (mouse.distanceTo(arbitraryVector.vertices[1]) < 10) {
            aaaa.stroke = "red";
          } else {
            aaaa.noStroke();
          }
        })
        .play();
    });

    return {
      "drawing-area": drawingArea,
    };
  },
});
</script>
