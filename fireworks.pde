//import com.hamoid.*;

//VideoExport videoExport;

int LINES = 10;
int CIRCLES = LINES + 1;

int TILES_X = 10;
int TILES_Y = 5;

float CIRCLE_MARGIN = max(10, 40 - (5 * TILES_X));
float LINE_SPEED_STEP = 0.5;
float MATCH_INTERVAL = 360 / 6 / TILES_X;

boolean DRAW_CIRCLES = false;
boolean DRAW_LINES = true;

int FRAME_RATE = 60;

float TRAILS_GAP = 3;
float MAX_TRAIL_OPACITY = 255;
float MIN_TRAIL_OPACITY = 110;
float TRAIL_OPACITY_STEP = (MAX_TRAIL_OPACITY - MIN_TRAIL_OPACITY) / 180 * TRAILS_GAP;
float TRAIL_OPACITY_FADE_STEP = 0.5; // 0.5 is a good value: nice animation which completes in time and is not too slow 

// Circles radiuses, never changing.
float radiuses[][][] = new float[TILES_X][TILES_Y][CIRCLES];
// Lines angles, never changing.
float baseAngles[][][] = new float[TILES_X][TILES_Y][LINES];
// Hues for every couple of lines, never changing.
float hues[][][][] = new float[TILES_X][TILES_Y][LINES][LINES];

// Base angles + sum of previous steps.
float angles[][][] = new float[TILES_X][TILES_Y][LINES];
// Opacity of the first trail, decremented at each step.
float trailOpacity[][][] = new float[TILES_X][TILES_Y][LINES];

void setup() {
  frameRate(FRAME_RATE);
  size(1600, 800);
  background(0);
  stroke(0);
  colorMode(HSB);

  println("Step", LINE_SPEED_STEP);
  println("Gap", MATCH_INTERVAL);
  println("Margin", CIRCLE_MARGIN);
  println("Trails gap", TRAILS_GAP);
  println("Trails opacity step", TRAIL_OPACITY_STEP);
  println("Trails opacity fade step", TRAIL_OPACITY_FADE_STEP);

  float maxRadius = width / 2 / TILES_X - CIRCLE_MARGIN;
  float circleGap = maxRadius / CIRCLES;

  for (int tileX = 0; tileX < TILES_X; tileX++) {
    for (int tileY = 0; tileY < TILES_Y; tileY++) {
      for (int i = 0; i < CIRCLES; i++) {
        radiuses[tileX][tileY][i] = maxRadius - circleGap * i;
      }
    
      for (int i = 0; i < LINES; i++) {
        baseAngles[tileX][tileY][i] = random(0, 360);
        trailOpacity[tileX][tileY][i] = MAX_TRAIL_OPACITY;
    
        for (int j = 0; j < LINES; j++) {
          hues[tileX][tileY][i][j] = random(255); // H
        }
      }
    }
  }

  //videoExport = new VideoExport(this);
  //videoExport.startMovie();
}

void drawCircle(float radius) {
  fill(0, 0);
  strokeWeight(2);
  stroke(255, 180);
  ellipse(width / (2 * TILES_X), height / (2 * TILES_Y), radius * 2, radius * 2);
}

float getHue(int tileX, int tileY, int line1, int line2) {
  return (line1 < line2) ?
    hues[tileX][tileY][line1][line2] :
    hues[tileX][tileY][line2][line1];
}

void drawLine(
  int tileX,
  int tileY,
  int trailIndex,
  float a_deg,
  float radius,
  int lineIndex,
  int matchingLineIndex,
  float baseOpacity
) {
  // All the x and y contain a number in the range [-radius, +radius].
  // The coordinates (x,y) are points on the circumference thanks to the values
  // calculated with sin and cos on the same angle.

  float radiusFixed = radius - 3;
  float a_rad = radians(a_deg);

  float x1 = sin(a_rad) * radiusFixed;
  float y1 = cos(a_rad) * radiusFixed;

  float x2 = sin(a_rad + PI) * radiusFixed;
  float y2 = cos(a_rad + PI) * radiusFixed;

  if (matchingLineIndex >= 0) {
    float h = getHue(tileX, tileY, lineIndex, matchingLineIndex);
    float s = 155;
    float b = 255;
    float a = baseOpacity - (TRAIL_OPACITY_STEP * float(trailIndex));

    stroke(h, s, b, a);
  } else if (trailIndex == 0) {
    stroke(255, 100);
  }

  strokeWeight(1);
  line(x1, y1, x2, y2);
}

int getMatchingLineIndex(int tileX, int tileY, int lineIndex) {
  int matchingLineIndex = -1;

  float a = angles[tileX][tileY][lineIndex];

  for (int j = 0; j < LINES; j++) {
    if (lineIndex % 2 != j % 2) {
      float a_j = angles[tileX][tileY][j];
      float gap = MATCH_INTERVAL;

      boolean inRange = (lineIndex % 2 == 0) ?
        (a >= a_j - gap && a <= a_j)
        || (a >= a_j + 180 - gap && a <= a_j + 180)
        || (a + 180 >= a_j - gap && a + 180 <= a_j)
        :
        (a >= a_j && a <= a_j + gap)
        || (a >= a_j + 180 && a <= a_j + 180 + gap)
        || (a + 180 >= a_j && a + 180 <= a_j + gap);

      if (inRange) {
        matchingLineIndex = j;
      }
    }
  }

  return matchingLineIndex;
}

void incrementAngles(int tileX, int tileY) {
  for (int i = 0; i < LINES; i++) {
    float angle = angles[tileX][tileY][i];

    float newValue = baseAngles[tileX][tileY][i];

    if (angle != 0) {
      angle += (i % 2 == 0 ? LINE_SPEED_STEP : -LINE_SPEED_STEP);

      newValue = angle < 0
        ? 360 + angle   // Start again from 360° plus the current angle (which is negative).
        : angle % 360;  // Reassign the angle in the range 0-359
    }

    angles[tileX][tileY][i] = newValue;
  }
}

void draw() {
  background(0);
  
  for (int tileX = 0; tileX < TILES_X; tileX++) {
    for (int tileY = 0; tileY < TILES_Y; tileY++) {
  
      pushMatrix();
      translate((width / TILES_X) * tileX, (height / TILES_Y) * tileY);
    
      pushMatrix();
      translate(width / (2 * TILES_X), height / (2 * TILES_Y));
      
      incrementAngles(tileX, tileY);
    
      for (int lineIndex = 0; lineIndex < LINES; lineIndex++) {
    
        int matchingLineIndex = getMatchingLineIndex(tileX, tileY, lineIndex);
    
        float angle = angles[tileX][tileY][lineIndex];
        float radius = radiuses[tileX][tileY][lineIndex];

        if (DRAW_LINES) {
          drawLine(tileX, tileY, 0, angle, radius, lineIndex, matchingLineIndex, 255);
        }

        if (matchingLineIndex >= 0) {
          int trailIndex = 0;

          // We draw trails until all the 180° spectrum is covered (don't care about how many of them will be there)

          for (float totalGap = TRAILS_GAP; totalGap < 180; totalGap += TRAILS_GAP) {
            float trailAngle = angle + totalGap;

            drawLine(tileX, tileY, trailIndex, trailAngle, radius, lineIndex, matchingLineIndex, trailOpacity[tileX][tileY][lineIndex]);

            trailOpacity[tileX][tileY][lineIndex] -=
              trailOpacity[tileX][tileY][lineIndex] == MAX_TRAIL_OPACITY ?
              TRAIL_OPACITY_STEP :
              TRAIL_OPACITY_FADE_STEP;

            trailIndex++;
          }
        }
        else if (trailOpacity[tileX][tileY][lineIndex] < MAX_TRAIL_OPACITY) {
          trailOpacity[tileX][tileY][lineIndex] = MAX_TRAIL_OPACITY;
        }
      }

      popMatrix();

      if (DRAW_CIRCLES) {
        for (int i = 0; i < CIRCLES; i++) {
          drawCircle(radiuses[tileX][tileY][i]);
        }
      }

      popMatrix();
    }
  }
  
  //videoExport.saveFrame();
}

/*
void keyPressed() {
  if (key == 'q') {
    videoExport.endMovie();
    exit();
  }
}
*/
