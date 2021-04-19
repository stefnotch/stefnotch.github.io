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
    const drawingArea = ref<HTMLDivElement>(null);
    const scaleUpFactor = 100;

    onMounted(() => {
      const app = new Pixi.Application({
        width: 256,
        height: 256,
        backgroundColor: 0xffffff,
        antialias: true,
      });
      drawingArea.value.appendChild(app.view);
      app.stage.x += app.screen.width / 2;
      app.stage.y += app.screen.height / 2;
      app.stage.scale.y = -1;

      let unitCircle = new Pixi.Graphics();
      unitCircle
        .lineStyle(1, 0x000000)
        .beginFill(0xffffff)
        .drawCircle(0, 0, 1 * scaleUpFactor)
        .endFill();
      app.stage.addChild(unitCircle);

      const green = 0x32aa23;

      let coneArrow = new Pixi.Graphics();
      coneArrow.lineStyle(1, green).lineTo(0, 1 * scaleUpFactor); // TODO: text as well
      app.stage.addChild(coneArrow);

      let coneTip = new Pixi.Graphics();
      coneTip
        .beginFill(green)
        .setTransform(0, 1 * scaleUpFactor)
        .drawCircle(0, 0, 8)
        .endFill();
      coneTip.interactive = true;
      coneTip.buttonMode = true;
      pointerMove(coneTip, (point) => {
        const length = Math.hypot(point.x, point.y);

        const result = new Pixi.Point(
          (point.x * scaleUpFactor) / length,
          (point.y * scaleUpFactor) / length
        );

        coneArrow.clear();
        coneArrow.lineStyle(1, green).lineTo(result.x, result.y);

        return result;
      });
      app.stage.addChild(coneTip);

      /*      let stage = new Konva.Stage({
        container: drawingArea.value,
        width: 285,
        height: 210,
      });

      let layer = new Konva.Layer({
        offsetX: -stage.size().width / 2,
        offsetY: -stage.size().height / 2,
      });

      let coneTip = new Konva.Circle({
        radius: 10,
        x: 1 * scaleUpFactor,
        y: 0 * scaleUpFactor,
        stroke: "blue",
        draggable: true,
        dragBoundFunc: (pos) => {
          console.log(pos);
          const len = length(pos);

          pos.x *= scaleUpFactor / len;
          pos.y *= scaleUpFactor / len;

          return pos;
        },
      });

      coneTip.on("dragmove", () => {
         let mouse = stage.getPointerPosition();
        mouse.x -= stage.size().width / 2;
        mouse.y -= stage.size().height / 2;

        let arrowPoints = coneArrow.points();
        //      arrowPoints[2] = mouse.x;
        //      arrowPoints[3] = mouse.y;

        arrowPoints[2] = coneTip.x();
        arrowPoints[3] = coneTip.y();
        // Renormalize
        coneArrow.points(arrowPoints);
      });

      let coneArrow = new Konva.Line({
        points: [0, 0, 1 * scaleUpFactor, 0 * scaleUpFactor],
        stroke: "blue",
      });

      layer.add(coneTip);
      layer.add(coneArrow);

      stage.add(layer);*/

      /*

      let two = new Two({  }).appendTo(
        
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
        .play();*/
    });

    return {
      "drawing-area": drawingArea,
    };
  },
});
</script>
