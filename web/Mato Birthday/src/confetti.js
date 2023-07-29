/**
 * @typedef {[number, number, number, number]} Color
 */

/**
 * @type {[Color, Color][]}
 */
const confettiColors = [
  [
    [21, 160, 235, 1],
    [98, 215, 242, 1],
  ],
  [
    [98, 215, 242, 1],
    [80, 239, 63, 1],
  ],
  [
    [235, 21, 152, 1],
    [244, 124, 172, 1],
  ],
  [
    [235, 182, 21, 1],
    [242, 237, 96, 1],
  ],
];

/**
 * @typedef {number[][]} PixelGrid
 */

/**
 * 0 = empty
 * 1 = color 1
 * 2 = color 2
 * @type {PixelGrid[]}
 */
const confettiTypes = [
  [
    [0, 1, 0],
    [1, 2, 1],
    [0, 1, 0],
  ],
  [
    [0, 0, 1, 1],
    [0, 1, 2, 1],
    [1, 2, 1, 0],
    [1, 1, 0, 0],
  ],
  [
    [0, 1, 1, 0],
    [1, 2, 2, 1],
    [0, 1, 1, 0],
  ],
];

const confettis = [];
for (const confettiType of confettiTypes) {
  for (const confettiColor of confettiColors) {
    confettis.push(await toConfettiBitmap(confettiType, confettiColor));
  }
}

export class ConfettiDrawer {
  constructor(ctx) {
    this.ctx = ctx;
    this.confettis = [];
  }

  addConfetti(ctx, x, y, velocity, angle, spread, count) {
    for (let i = 0; i < count; i++) {
      const confettiImage = confettis[Math.floor(Math.random() * confettis.length)];
      const confettiVelocity = Math.random() * velocity + velocity / 2;
      const confettiAngle = -angle + Math.random() * spread - spread / 2;
      const velocityX = Math.cos(confettiAngle) * confettiVelocity;
      const velocityY = Math.sin(confettiAngle) * confettiVelocity;
      const rotation = Math.random() * Math.PI * 2;
      const rotationVelocity = Math.random() * 0.1 - 0.05;
      const gravity = Math.random() * 0.1 + 0.1;
      const size = 2 + Math.round(Math.random() * 2);
      const confetti = new Confetti(ctx, {
        confettiImage,
        x: x,
        y: y,
        velocityX,
        velocityY,
        rotation,
        rotationVelocity,
        gravity, size
      });
      this.confettis.push(confetti);
    }
  }

  render(ctx) {
    this.confettis.forEach((confetti) => confetti.render(ctx));
    this.confettis = this.confettis.filter((confetti) => confetti.isAlive);
  }
}

/**
 * 
 * @param {PixelGrid} pixels 
 * @param {[Color, Color]} colors 
 */
async function toConfettiBitmap(pixels, colors) {
  const width = pixels[0].length;
  const height = pixels.length;
  let image = new ImageData(width, height);
  const data = image.data;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const pixel = pixels[y][x];
      if (pixel === 0) continue;
      const color = colors[pixel - 1];
      const index = (y * width + x) * 4;
      data[index + 0] = color[0];
      data[index + 1] = color[1];
      data[index + 2] = color[2];
      data[index + 3] = color[3] * 255;
    }
  }
  return await createImageBitmap(image);
}

/**
 * @typedef {{
 * confettiImage: ImageBitmap, x: number, y: number,
 * velocityX: number, velocityY: number, rotation: number, rotationVelocity: number, gravity: number
 * }} ConfettiOptions
 */

class Confetti {
  constructor(ctx, options) {
    this.isAlive = true;

    this.image = options.confettiImage;
    this.width = this.image.width;
    this.height = this.image.height;
    this.x = options.x;
    this.y = options.y;
    this.velocityX = options.velocityX;
    this.velocityY = options.velocityY;
    this.rotation = options.rotation;
    this.rotationVelocity = options.rotationVelocity;
    this.gravity = options.gravity;
    this.size = options.size;
  }

  render(ctx) {
    this.x += this.velocityX;
    this.y += this.velocityY;
    this.velocityY += this.gravity;
    this.rotation += this.rotationVelocity;
    // Air resistance
    this.velocityX *= 0.99;
    this.velocityY *= 0.99;
    this.rotationVelocity *= 0.99;

    // https://stackoverflow.com/a/38079796/3492994
    ctx.setTransform(this.size, 0, 0, this.size, this.x, this.y);
    ctx.rotate(this.rotation);
    ctx.drawImage(this.image, -this.width / 2, -this.height / 2, this.width, this.height);
    // Delete confetti if it's out of bounds
    if (this.y > ctx.canvas.height) {
      this.isAlive = false;
    }
  }
}
