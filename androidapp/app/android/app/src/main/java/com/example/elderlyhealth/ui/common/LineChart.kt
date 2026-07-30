package com.example.elderlyhealth.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.elderlyhealth.data.model.VitalDataPoint

@Composable
fun LineChart(
    dataPoints: List<VitalDataPoint>,
    modifier: Modifier = Modifier,
    lineColor: Color = MaterialTheme.colorScheme.primary,
    baselineMin: Double? = null,
    baselineMax: Double? = null,
    gridLines: Int = 4,
    horizontalPadding: Dp = 16.dp
) {
    if (dataPoints.isEmpty()) {
        Box(modifier = modifier, contentAlignment = androidx.compose.ui.Alignment.Center) {
            Text("暂无数据", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        return
    }

    Column(modifier = modifier) {
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(start = horizontalPadding, end = horizontalPadding)
        ) {
            val values = dataPoints.map { it.value }
            val min = values.min()
            val max = values.max()
            val valueRange = if (max == min) 1.0 else max - min
            val padding = size.height * 0.1f
            val chartHeight = size.height - padding * 2
            val chartWidth = size.width

            // Grid lines
            val gridColor = Color.LightGray.copy(alpha = 0.5f)
            for (i in 0..gridLines) {
                val y = padding + (chartHeight * i / gridLines)
                drawLine(
                    color = gridColor,
                    start = Offset(0f, y),
                    end = Offset(chartWidth, y),
                    strokeWidth = 1f
                )
            }

            // Baseline area
            if (baselineMin != null && baselineMax != null && baselineMax > baselineMin) {
                val topRatio = ((max - baselineMax) / valueRange).toFloat().coerceIn(0f, 1f)
                val bottomRatio = ((max - baselineMin) / valueRange).toFloat().coerceIn(0f, 1f)
                val y1 = padding + chartHeight * topRatio
                val y2 = padding + chartHeight * bottomRatio
                drawRect(
                    color = Color(0xFF4CAF50).copy(alpha = 0.08f),
                    topLeft = Offset(0f, y1),
                    size = androidx.compose.ui.geometry.Size(chartWidth, (y2 - y1).coerceAtLeast(0f))
                )
            }

            if (dataPoints.size < 2) return@Canvas

            // Data line
            val stepX = chartWidth / (dataPoints.size - 1).coerceAtLeast(1)
            val path = Path()
            val points = dataPoints.mapIndexed { index, dp ->
                val x = stepX * index
                val ratio = ((max - dp.value) / valueRange).toFloat().coerceIn(0f, 1f)
                val y = padding + chartHeight * ratio
                Offset(x, y)
            }

            path.moveTo(points[0].x, points[0].y)
            for (i in 1 until points.size) {
                path.lineTo(points[i].x, points[i].y)
            }

            drawPath(
                path = path,
                color = lineColor,
                style = Stroke(
                    width = 3f,
                    cap = StrokeCap.Round,
                    join = StrokeJoin.Round
                )
            )

            // Data points
            points.forEach { point ->
                drawCircle(
                    color = lineColor,
                    radius = 4f,
                    center = point
                )
            }
        }
    }
}
