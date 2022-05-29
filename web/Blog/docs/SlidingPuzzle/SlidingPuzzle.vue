<script setup lang="ts">
import { ref, computed, type Ref, type ComputedRef } from "vue";

const Cells = {
  Empty: 0,
  Stone: 1,
  Goal: 2,
};

type Cell = typeof Cells[keyof typeof Cells];
type Player = {
  x: Ref<number>;
  y: Ref<number>;
  cell: ComputedRef<Cell>;
};
type Position = {
  readonly x: number;
  readonly y: number;
};

const board = ref(createBoard(10, 10));
const player = ref(createPlayer(board.value));
const playerPosition = computed<Position>(() => {
  return {
    x: player.value.x,
    y: player.value.y,
  };
});
const solution = ref<{ index: number; position: Position }[]>([]);

(async () => {
  while (true) {
    const done = placeRocksAndGoal(board.value);
    if (done) break;

    await new Promise((resolve) => setTimeout(resolve, 0));
  }
})();

function createBoard(width: number, height: number): Cell[][] {
  if (width < 3 || height < 3) {
    throw new Error("Board must have at least 3x3 cells");
  }

  const board: Cell[][] = [];
  for (let i = 0; i < height; i++) {
    const row: Cell[] = [];
    for (let j = 0; j < width; j++) {
      if (i <= 0 || j <= 0 || i >= height - 1 || j >= width - 1) {
        row.push(Cells.Stone);
      } else {
        row.push(Cells.Empty);
      }
    }
    board.push(row);
  }

  // Player starting pos
  board[height - 1][width - 2] = Cells.Empty;

  return board;
}

function placeRocksAndGoal(board: Cell[][]): boolean {
  const height = board.length;
  const width = board[0].length;

  let numberOfRocks = Math.floor((Math.random() * (width * height)) / 3);
  while (numberOfRocks > 0) {
    for (let trial = 0; trial < 2; trial++) {
      const copy = copyBoard(board);

      // Place the goal randomly
      const goalX = Math.floor(Math.random() * (width - 2)) + 1;
      const goalY = Math.floor(Math.random() * (height - 2)) + 1;
      copy[goalY][goalX] = Cells.Goal;

      // Place rocks randomly
      for (let i = 0; i < numberOfRocks; i++) {
        const x = Math.floor(Math.random() * (width - 2)) + 1;
        const y = Math.floor(Math.random() * (height - 2)) + 1;
        if (copy[y][x] === Cells.Empty) {
          copy[y][x] = Cells.Stone;
        } else {
          // Sometimes give up and decide to not place a rock at all
          if (Math.random() > 0.5) i--;
        }
      }

      const solutionSteps = getSolution(copy);
      if (solutionSteps != null) {
        copyBoardTo(copy, board);
        let v = solutionSteps;
        while (v != null) {
          solution.value.unshift({
            index: 0,
            position: v.position,
          });
          for (
            let stepIndex = solution.value.length - 1;
            stepIndex > 0;
            stepIndex--
          ) {
            solution.value[stepIndex].index = stepIndex;
          }

          v = v.previous;
        }
        return true;
      }
    }

    numberOfRocks -= 1;
  }

  console.log("Oh no, it failed. Retrying...?");
  return false;
}

function copyBoard(board: Cell[][]) {
  return board.map((row) => row.slice());
}
function copyBoardTo(board: Cell[][], target: Cell[][]) {
  for (let i = 0; i < board.length; i++) {
    for (let j = 0; j < board[i].length; j++) {
      target[i][j] = board[i][j];
    }
  }
}

type SolutionStep = {
  position: Position;
  direction: Position;
  previous: SolutionStep | null;
};

function getSolution(board: Cell[][]): SolutionStep | null {
  const visited = new Set<string>();
  const addToVisited = (pos: Position) => {
    visited.add(`${pos.x},${pos.y}`);
  };
  const visitedContains = (pos: Position) => {
    return visited.has(`${pos.x},${pos.y}`);
  };

  const queue: SolutionStep[] = [];

  const possibleDirections = [
    { x: -1, y: 0 },
    { x: 1, y: 0 },
    { x: 0, y: -1 },
    { x: 0, y: 1 },
  ];

  // Now insert the player's position
  addToVisited(playerPosition.value);
  possibleDirections.forEach((dir) => {
    queue.push({
      position: playerPosition.value,
      direction: dir,
      previous: null,
    });
  });

  while (queue.length > 0) {
    const step = queue.shift()!;
    const { position, direction } = step;

    const nextPosition = findWallInDirection(position, direction, board);

    if (board[nextPosition.y][nextPosition.x] === Cells.Goal) {
      return {
        position: nextPosition,
        direction,
        previous: step,
      };
    }

    if (visitedContains(nextPosition)) {
      continue;
    }

    addToVisited(nextPosition);
    possibleDirections.forEach((dir) => {
      queue.push({
        position: nextPosition,
        direction: dir,
        previous: step,
      });
    });
  }

  return null;
}

function createPlayer(board: Cell[][]): Player {
  const height = board.length;
  const width = board[0].length;
  const player: Player = {
    y: ref(height - 1),
    x: ref(width - 2),
    cell: computed(() => board[player.y.value][player.x.value]),
  };

  if (player.cell.value === Cells.Stone) {
    throw new Error("Player cannot start on a stone");
  }

  return player;
}

function findWallInDirection(
  start: Position,
  direction: Position,
  board: Cell[][]
): Position {
  while (true) {
    const next: Position = {
      x: start.x + direction.x,
      y: start.y + direction.y,
    };

    if (
      next.x < 0 ||
      next.x >= board[0].length ||
      next.y < 0 ||
      next.y >= board.length
    ) {
      return start;
    }

    if (board[next.y][next.x] === Cells.Stone) {
      return start;
    }

    start = next;
  }
}

function movePlayerTo(position: Position) {
  player.value.x = position.x;
  player.value.y = position.y;
}

function displayCell(cell: Cell): string {
  if (cell === Cells.Empty) {
    return " ";
  } else if (cell === Cells.Stone) {
    return "⛰";
  } else if (cell === Cells.Goal) {
    return "🐟";
  }
}

function handleInput(ev: KeyboardEvent) {
  if (ev.code == "ArrowUp") {
    console.log("up");
    movePlayerTo(
      findWallInDirection(playerPosition.value, { x: 0, y: -1 }, board.value)
    );
  } else if (ev.code == "ArrowDown") {
    console.log("down");
    movePlayerTo(
      findWallInDirection(playerPosition.value, { x: 0, y: 1 }, board.value)
    );
  } else if (ev.code == "ArrowLeft") {
    console.log("left");
    movePlayerTo(
      findWallInDirection(playerPosition.value, { x: -1, y: 0 }, board.value)
    );
  } else if (ev.code == "ArrowRight") {
    console.log("right");
    movePlayerTo(
      findWallInDirection(playerPosition.value, { x: 1, y: 0 }, board.value)
    );
  }
}
</script>

<template>
  <table :tabIndex="0" className="game-table" @keydown="handleInput($event)">
    <tbody>
      <tr v-for="(row, y) in board">
        <td v-for="(cell, x) in row">
          <span>{{ displayCell(cell) }}</span>
          <span
            v-if="x == player.x && y == player.y"
            style="
              position: absolute;
              transform: translate(0%, -50%);
              text-align: center;
            "
            >🐈</span
          >
        </td>
      </tr>
    </tbody>
  </table>

  Solution in an arcane language understood by computer-wizards:
  <pre>{{ solution }}</pre>
</template>

<style>
.game-table {
  table-layout: fixed;
}
.game-table:focus > tbody {
  outline: 1px solid #000;
}
.game-table::after {
  content: "<Paused - click to play>";
}

.game-table:focus::after {
  content: "Playing";
}
</style>
