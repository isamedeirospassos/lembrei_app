package com.example.lembrei_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class LembreiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val data = HomeWidgetPlugin.getData(context)

            val views = RemoteViews(context.packageName, R.layout.lembrei_widget)

            views.setTextViewText(
                R.id.widget_title,
                data.getString("widget_title", "📋 hoje")
            )
            views.setTextViewText(
                R.id.widget_lembretes,
                data.getString("widget_lembretes", "nenhum lembrete hoje ✨")
            )
            views.setTextViewText(
                R.id.widget_footer,
                data.getString("widget_footer", "")
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}