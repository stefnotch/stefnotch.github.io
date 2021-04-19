<template>
  <p>Cone Angle <input type="number" min="0" max="180" v-model="angle" /></p>
  <p>
    Cone Direction [{{ direction.x.toFixed(3) }}, {{ direction.y.toFixed(3) }}]
  </p>
  <p>Vector [{{ myVector.x.toFixed(3) }}, {{ myVector.y.toFixed(3) }}]</p>
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
import * as Pixi from "pixi.js";

function pointerMove(
  element: Pixi.Graphics,
  callback: (point: Pixi.Point) => Pixi.Point
) {
  element
    .on("pointerdown", function (event) {
      this.data = event.data;
      this.dragging = true;
    })
    .on("pointerup", function (event) {
      this.dragging = false;
      this.data = null;
    })
    .on("pointerupoutside", function (event) {
      this.dragging = false;
      this.data = null;
    })
    .on("pointermove", function (event) {
      if (this.dragging) {
        const newPosition =
          callback(this.data.getLocalPosition(this.parent)) ??
          new Pixi.Point(this.x, this.y);
        this.x = newPosition.x;
        this.y = newPosition.y;
      }
    });
}

export default defineComponent({
  setup(props, context) {
    const drawingArea = ref<HTMLDivElement | null>(null);
    const scaleUpFactor = 100;

    // Cone angle
    const angle = ref(60);
    // Cone direction (normalized)
    const direction = ref(new Pixi.Point(0, 1));
    // My direction vector (to clamp)
    const myVector = ref(new Pixi.Point(-0.2, -0.8));

    onMounted(() => {
      const app = new Pixi.Application({
        width: 256,
        height: 256,
        backgroundColor: 0xffffff,
        antialias: true,
      });
      drawingArea.value?.appendChild(app.view);
      app.stage.x += app.screen.width / 2;
      app.stage.y += app.screen.height / 2;
      app.stage.scale.y = -1;

      let unitCircle = new Pixi.Graphics();
      unitCircle
        .lineStyle(2, 0x000000)
        .beginFill(0xffffff)
        .drawCircle(0, 0, 1 * scaleUpFactor)
        .endFill();
      app.stage.addChild(unitCircle);

      // cone arrow
      {
        const green = 0x32aa23;

        let coneArrow = new Pixi.Graphics();
        watch(
          [direction, angle],
          ([dir, ang]) => {
            coneArrow.clear();

            coneArrow
              .lineStyle(0)
              .beginFill(0xffaaff, 0.5)
              .arc(
                0,
                0,
                0.99 * scaleUpFactor,
                (-ang * Math.PI) / 180 + Math.atan2(dir.y, dir.x),
                (ang * Math.PI) / 180 + Math.atan2(dir.y, dir.x)
              )
              .lineTo(0, 0)
              .endFill();

            coneArrow
              .lineStyle(1, green)
              .lineTo(dir.x * scaleUpFactor, dir.y * scaleUpFactor);
          },
          {
            immediate: true,
          }
        ); // TODO: text as well (when hovering over the corresponding thingy)
        app.stage.addChild(coneArrow);

        let coneTip = new Pixi.Graphics();
        coneTip
          .beginFill(green)
          .setTransform(
            direction.value.x * scaleUpFactor,
            direction.value.y * scaleUpFactor
          )
          .drawCircle(0, 0, 8)
          .endFill();
        coneTip.interactive = true;
        coneTip.buttonMode = true;
        app.stage.addChild(coneTip);
        pointerMove(coneTip, (point) => {
          const length = Math.hypot(point.x, point.y);
          direction.value = new Pixi.Point(point.x / length, point.y / length);

          return new Pixi.Point(
            direction.value.x * scaleUpFactor,
            direction.value.y * scaleUpFactor
          );
        });
      }

      // my vector
      {
        const blue = 0x3232cc;
        let myVectorArrow = new Pixi.Graphics();
        watch(
          myVector,
          (value) => {
            myVectorArrow.clear();
            myVectorArrow
              .lineStyle(1, blue)
              .lineTo(value.x * scaleUpFactor, value.y * scaleUpFactor);
          },
          { immediate: true }
        ); // TODO: text as well
        app.stage.addChild(myVectorArrow);

        let myVectorTip = new Pixi.Graphics();
        myVectorTip
          .beginFill(blue)
          .setTransform(
            myVector.value.x * scaleUpFactor,
            myVector.value.y * scaleUpFactor
          )
          .drawCircle(0, 0, 8)
          .endFill();
        myVectorTip.interactive = true;
        myVectorTip.buttonMode = true;
        app.stage.addChild(myVectorTip);
        pointerMove(myVectorTip, (point) => {
          myVector.value = new Pixi.Point(
            point.x / scaleUpFactor,
            point.y / scaleUpFactor
          );
          return point;
        });
      }

      // clamp to 90 degree
      {
        let clampToPie = new Pixi.Graphics();
        const purple = 0xaa32bb;
        watch(
          [direction, angle, myVector],
          ([dir, ang, vec]) => {
            const length = Math.hypot(vec.x, vec.y);
            const normalizedVec = new Pixi.Point(
              vec.x / length,
              vec.y / length
            );
            const dotProduct =
              dir.x * normalizedVec.x + dir.y * normalizedVec.y; // We need normalized vectors to actually find an *angle*

            const clampedToPie = new Pixi.Point(
              vec.x - dir.x * dotProduct * length,
              vec.y - dir.y * dotProduct * length
            );

            clampToPie.clear();
            clampToPie
              .lineStyle(1, purple)
              .moveTo(vec.x * scaleUpFactor, vec.y * scaleUpFactor)
              .lineTo(
                clampedToPie.x * scaleUpFactor,
                clampedToPie.y * scaleUpFactor
              );

            if (dotProduct > Math.cos((ang * Math.PI) / 180)) {
              const lightBlue = 0xaaaaff;

              clampToPie
                .lineStyle(0)
                .beginFill(lightBlue)
                .drawCircle(vec.x * scaleUpFactor, vec.y * scaleUpFactor, 8)
                .endFill();
            }

            const clampedLength = Math.hypot(clampedToPie.x, clampedToPie.y);
            const coneRadius = Math.sin((ang * Math.PI) / 180); // being on the unit circle is convenient as heck
            const correctedToPie = new Pixi.Point(
              (clampedToPie.x / clampedLength) * coneRadius,
              (clampedToPie.y / clampedLength) * coneRadius
            );

            clampToPie
              .lineStyle(1, purple)
              .moveTo(0, 0)
              .lineTo(
                correctedToPie.x * scaleUpFactor,
                correctedToPie.y * scaleUpFactor
              )
              .lineStyle(1, purple, 0.4)
              .lineTo(
                (correctedToPie.x / coneRadius) * scaleUpFactor,
                (correctedToPie.y / coneRadius) * scaleUpFactor
              );
          },
          {
            immediate: true,
          }
        );
        app.stage.addChild(clampToPie);
      }

      // TODO: Don't 'normalize' the entire vector at the end (since that would end up going too far :thinking:)
      // TODO: normalizing after the 90 deg clamping works
    });

    return {
      "drawing-area": drawingArea,
      angle,
      direction,
      myVector,
    };
  },
});
</script>
