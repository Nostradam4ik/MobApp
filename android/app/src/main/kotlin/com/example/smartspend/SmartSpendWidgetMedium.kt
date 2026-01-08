package com.example.smartspend

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Locale

class SmartSpendWidgetMedium : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_medium).apply {
                // Récupérer les données
                val monthTotal = widgetData.getString("month_total", "0.0")?.toDoubleOrNull() ?: 0.0
                val weekTotal = widgetData.getString("week_total", "0.0")?.toDoubleOrNull() ?: 0.0
                val todayTotal = widgetData.getString("today_total", "0.0")?.toDoubleOrNull() ?: 0.0
                val budgetLimit = widgetData.getString("budget_limit", "0.0")?.toDoubleOrNull() ?: 0.0
                val budgetPercent = widgetData.getString("budget_percent", "0.0")?.toDoubleOrNull() ?: 0.0
                val currencySymbol = widgetData.getString("currency_symbol", "€") ?: "€"
                val lastUpdate = widgetData.getString("last_update", "--:--") ?: "--:--"

                // Formater les montants
                val formatter = NumberFormat.getCurrencyInstance(Locale.FRANCE)

                fun formatAmount(amount: Double): String {
                    return formatter.format(amount).replace("€", currencySymbol)
                }

                // Mettre à jour les vues
                setTextViewText(R.id.widget_amount, formatAmount(monthTotal))
                setTextViewText(R.id.widget_today, formatAmount(todayTotal))
                setTextViewText(R.id.widget_week, formatAmount(weekTotal))
                setTextViewText(R.id.widget_budget, "${budgetPercent.toInt()}%")
                setTextViewText(R.id.widget_last_update, "Mis à jour à $lastUpdate")

                setProgressBar(R.id.widget_progress, 100, budgetPercent.toInt().coerceIn(0, 100), false)

                // Intent pour ouvrir l'app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    data = Uri.parse("smartspend://open_app")
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_amount, openAppPendingIntent)

                // Intent pour ajouter une dépense
                val addExpenseIntent = Intent(context, MainActivity::class.java).apply {
                    data = Uri.parse("smartspend://add_expense")
                }
                val addExpensePendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    addExpenseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_add_button, addExpensePendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
