package com.everittventures.salonboothmath

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.NumberFormat

private val Berry = Color(0xFF4A1835)
private val Ink = Color(0xFF0B1220)
private val Pink = Color(0xFFFF3D6E)
private val Page = Color.White

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { SalonBoothHome() } }
    }
}

@Composable
fun SalonBoothHome() {
    var services by remember { mutableStateOf("1240") }
    var tips by remember { mutableStateOf("160") }
    var supplies by remember { mutableStateOf("45") }
    var showPaywall by remember { mutableStateOf(false) }
    val context = LocalContext.current

    val service = services.toDoubleOrNull() ?: 0.0
    val tip = tips.toDoubleOrNull() ?: 0.0
    val supply = supplies.toDoubleOrNull() ?: 0.0
    val weeklyRent = 250.0
    val cardFees = (tip + service * .70) * .029
    val takeHome = service + tip - weeklyRent - cardFees - supply
    val money = NumberFormat.getCurrencyInstance().format(takeHome)

    Column(Modifier.fillMaxSize().background(Page).verticalScroll(rememberScrollState())) {
        Box(Modifier.fillMaxWidth().background(Berry).padding(horizontal = 18.dp, vertical = 20.dp)) {
            Text(stringResource(R.string.this_week), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.align(Alignment.Center))
        }

        Column(Modifier.padding(horizontal = 22.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            MoneyField(stringResource(R.string.services), services) { services = it }
            MoneyField(stringResource(R.string.tips), tips) { tips = it }
            MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }

            Spacer(Modifier.height(10.dp))
            Text(stringResource(R.string.you_took_home), color = Berry, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp, modifier = Modifier.align(Alignment.CenterHorizontally))
            Text(money, color = Ink, fontWeight = FontWeight.ExtraBold, fontSize = 56.sp, modifier = Modifier.align(Alignment.CenterHorizontally))

            Button(onClick = { showPaywall = true }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth().height(62.dp)) {
                Text(stringResource(R.string.save_week), fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
            }
            TextButton(onClick = { showPaywall = true }, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.breakdown), color = Berry, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = { showPaywall = true }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.compare), color = Berry, fontWeight = FontWeight.Bold) }
                OutlinedButton(onClick = { showPaywall = true }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.history), color = Berry, fontWeight = FontWeight.Bold) }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = {
                    val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, "${context.getString(R.string.you_took_home)} $money\nSalon Booth Math") }
                    context.startActivity(Intent.createChooser(intent, context.getString(R.string.share)))
                }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.share), color = Berry, fontWeight = FontWeight.Bold) }
                OutlinedButton(onClick = { }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.settings), color = Berry, fontWeight = FontWeight.Bold) }
            }
        }
    }

    if (showPaywall) {
        AlertDialog(onDismissRequest = { showPaywall = false }, title = { Text(stringResource(R.string.unlock), fontWeight = FontWeight.ExtraBold) }, text = { Text(stringResource(R.string.paywall_body)) }, confirmButton = { Button(onClick = { showPaywall = false }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink)) { Text("$4.99", fontWeight = FontWeight.ExtraBold) } }, dismissButton = { TextButton(onClick = { showPaywall = false }) { Text("Not now") } })
    }
}

@Composable
private fun MoneyField(label: String, value: String, onValue: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(label, color = Ink, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold)
        OutlinedTextField(value = value, onValueChange = onValue, singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), textStyle = LocalTextStyle.current.copy(fontSize = 30.sp, fontWeight = FontWeight.ExtraBold, color = Ink), modifier = Modifier.fillMaxWidth().height(68.dp), shape = RoundedCornerShape(18.dp), prefix = { Text(NumberFormat.getCurrencyInstance().currency?.symbol ?: "$") })
    }
}
