package com.loipham.lingua.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.loipham.lingua.MainActivity
import com.loipham.lingua.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget màn hình chính: nhỏ (2x2), vừa (4x2), lớn (4x4) — cùng dữ liệu, khác layout. */
abstract class LinguaWidgetProvider(private val layout: Int) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = WidgetData.from(widgetData)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, layout)
            bind(context, views, data)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    protected open fun bind(context: Context, views: RemoteViews, data: WidgetData) {
        views.setOnClickPendingIntent(R.id.widget_root, launch(context, "home"))
        views.setTextViewText(R.id.widget_streak, data.streak.toString())
        views.setTextColor(
            R.id.widget_streak,
            context.getColor(if (data.streak > 0) R.color.widget_streak else R.color.widget_muted),
        )
        views.setTextViewText(R.id.widget_streak_label, data.labelStreak)
        views.setProgressBar(R.id.widget_goal_progress, data.goal, data.today.coerceAtMost(data.goal), false)
        views.setTextViewText(R.id.widget_goal_count, "${data.today}/${data.goal}")
    }

    /** Phần bên phải của widget vừa / lớn: mục tiêu hôm nay, mục cần ôn, học tiếp. */
    protected fun bindSummary(context: Context, views: RemoteViews, data: WidgetData) {
        views.setTextViewText(R.id.widget_today_label, data.labelToday)
        views.setTextViewText(R.id.widget_due, data.labelDue)
        views.setTextColor(
            R.id.widget_due,
            context.getColor(if (data.due > 0) R.color.widget_brand else R.color.widget_muted),
        )
        views.setOnClickPendingIntent(R.id.widget_due, launch(context, if (data.due > 0) "review" else "home"))
        views.setTextViewText(
            R.id.widget_continue,
            "${data.courseFlag} ${data.labelContinue}: ${data.continueTitle}",
        )
    }

    protected fun launch(context: Context, path: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("lingua://widget/$path"),
        )
}

class SmallWidgetProvider : LinguaWidgetProvider(R.layout.widget_small)

class MediumWidgetProvider : LinguaWidgetProvider(R.layout.widget_medium) {
    override fun bind(context: Context, views: RemoteViews, data: WidgetData) {
        super.bind(context, views, data)
        bindSummary(context, views, data)
    }
}

class LargeWidgetProvider : LinguaWidgetProvider(R.layout.widget_large) {
    private val barIds = intArrayOf(
        R.id.widget_bar0, R.id.widget_bar1, R.id.widget_bar2, R.id.widget_bar3,
        R.id.widget_bar4, R.id.widget_bar5, R.id.widget_bar6,
    )
    private val dayIds = intArrayOf(
        R.id.widget_day0, R.id.widget_day1, R.id.widget_day2, R.id.widget_day3,
        R.id.widget_day4, R.id.widget_day5, R.id.widget_day6,
    )

    override fun bind(context: Context, views: RemoteViews, data: WidgetData) {
        super.bind(context, views, data)
        bindSummary(context, views, data)
        // Cột = ProgressBar dọc (clip từ dưới lên) — chạy được trên mọi API, theo màu sáng/tối.
        val peak = (data.bars.maxOrNull() ?: 0).coerceAtLeast(1)
        for (i in 0 until 7) {
            val value = data.bars[i]
            views.setProgressBar(barIds[i], peak, if (value == 0) 0 else value.coerceAtLeast(peak / 20 + 1), false)
            views.setTextViewText(dayIds[i], data.weekdays[i])
        }
    }
}
