package com.example.smartspend

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Locale

class SmartSpendWidgetSmall : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_small).apply {
                // Récupérer les données
                val monthTotal = widgetData.getString("month_total", "0.0")?.toDoubleOrNull() ?: 0.0
                val budgetLimit = widgetData.getString("budget_limit", "0.0")?.toDoubleOrNull() ?: 0.0
                val budgetPercent = widgetData.getString("budget_percent", "0.0")?.toDoubleOrNull() ?: 0.0
                val currencySymbol = widgetData.getString("currency_symbol", "€") ?: "€"

                // Formater le montant
                val formatter = NumberFormat.getCurrencyInstance(Locale.FRANCE)
                val formattedAmount = formatter.format(monthTotal).replace("€", currencySymbol)

                // Mettre à jour les vues
                setTextViewText(R.id.widget_amount, formattedAmount)
                setProgressBar(R.id.widget_progress, 100, budgetPercent.toInt().coerceIn(0, 100), false)

                if (budgetLimit > 0) {
                    setTextViewText(R.id.widget_budget_info, "Budget: ${budgetPercent.toInt()}%")
                } else {
                    setTextViewText(R.id.widget_budget_info, "")
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
