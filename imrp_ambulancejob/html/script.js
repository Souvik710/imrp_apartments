/* =========================================================
   IMRP Ambulance Job - NUI JavaScript
   MDT, Death Screen, Dispatch, Patient Inspection
   ========================================================= */

let currentPage = 'dashboard';
let playerData = {};

/* =========================================================
   NUI MESSAGE HANDLER
   ========================================================= */

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'showDeathScreen':
            showDeathScreen(data);
            break;
        case 'hideDeathScreen':
            hideDeathScreen();
            break;
        case 'updateDeathTimer':
            updateDeathTimer(data);
            break;
        case 'showDispatchAlert':
            showDispatchAlert(data.data);
            break;
        case 'showPatientInspection':
            showPatientInspection(data.data);
            break;
        case 'openMDT':
            openMDT(data.playerData);
            break;
        case 'closeMDT':
            closeMDTUI();
            break;
    }
});

/* =========================================================
   DEATH SCREEN
   ========================================================= */

function showDeathScreen(data) {
    const screen = document.getElementById('deathScreen');
    screen.classList.remove('hidden');

    updateDeathState(data.state);
    updateDeathTimer(data);
}

function hideDeathScreen() {
    document.getElementById('deathScreen').classList.add('hidden');
}

function updateDeathState(state) {
    const title = document.getElementById('deathTitle');
    const subtitle = document.getElementById('deathSubtitle');
    const btnDistress = document.getElementById('btnDistress');
    const btnCrawl = document.getElementById('btnCrawl');
    const btnRespawn = document.getElementById('btnRespawn');
    const hint = document.getElementById('deathHint');

    switch (state) {
        case 'laststand':
            title.textContent = 'CRITICALLY INJURED';
            subtitle.textContent = 'EMS can save you. Press G for distress signal.';
            btnDistress.classList.remove('hidden');
            btnCrawl.classList.remove('hidden');
            btnRespawn.classList.add('hidden');
            hint.textContent = 'Press G to send distress signal';
            break;
        case 'unconscious':
            title.textContent = 'UNCONSCIOUS';
            subtitle.textContent = 'Only EMS can save you now.';
            btnDistress.classList.add('hidden');
            btnCrawl.classList.add('hidden');
            btnRespawn.classList.add('hidden');
            hint.textContent = 'Waiting for EMS...';
            break;
        case 'dead':
            title.textContent = 'DEAD';
            subtitle.textContent = 'Wait for respawn timer or EMS.';
            btnDistress.classList.add('hidden');
            btnCrawl.classList.add('hidden');
            hint.textContent = '';
            break;
    }
}

function updateDeathTimer(data) {
    const timerText = document.getElementById('deathTimerText');
    const timer = data.timer || 0;
    const mins = Math.floor(timer / 60);
    const secs = timer % 60;
    timerText.textContent = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');

    updateDeathState(data.state);

    if (data.state === 'dead' && data.canRespawn) {
        document.getElementById('btnRespawn').classList.remove('hidden');
        document.getElementById('deathHint').textContent = 'Press E to respawn';
    }
}

function sendDistress() {
    fetch('https://imrp_ambulancejob/sendDistress', { method: 'POST', body: JSON.stringify({}) });
}

function toggleCrawl() {
    fetch('https://imrp_ambulancejob/toggleCrawl', { method: 'POST', body: JSON.stringify({}) });
}

function requestRespawn() {
    fetch('https://imrp_ambulancejob/requestRespawn', { method: 'POST', body: JSON.stringify({}) });
}

/* =========================================================
   DISPATCH ALERT
   ========================================================= */

function showDispatchAlert(data) {
    const alert = document.getElementById('dispatchAlert');
    document.getElementById('dispatchType').textContent = data.type_label || 'Emergency';
    document.getElementById('dispatchLocation').textContent = data.location || 'Unknown';
    document.getElementById('dispatchCaller').textContent = data.caller_name || 'Unknown';
    document.getElementById('dispatchUnits').textContent = data.responding_units || '0';
    document.getElementById('dispatchDesc').textContent = data.description || 'No details';
    document.getElementById('dispatchPriority').textContent = (data.priority || 'medium').toUpperCase();

    alert.classList.remove('hidden');

    setTimeout(function() {
        alert.classList.add('hidden');
    }, 15000);
}

/* =========================================================
   PATIENT INSPECTION
   ========================================================= */

function showPatientInspection(data) {
    const panel = document.getElementById('patientInspection');
    panel.classList.remove('hidden');

    document.getElementById('inspPatientName').textContent = data.patientName || 'Unknown';
    document.getElementById('inspPatientId').textContent = 'ID: ' + (data.patientId || '---');

    const bloodLevel = data.bloodLevel || 100;
    const painLevel = data.painLevel || 0;
    const bleedLevel = data.bleedLevel || 0;

    document.getElementById('inspBlood').textContent = bloodLevel + '%';
    document.getElementById('inspBloodBar').style.width = bloodLevel + '%';

    document.getElementById('inspPain').textContent = painLevel + '%';
    document.getElementById('inspPainBar').style.width = painLevel + '%';

    document.getElementById('inspBleed').textContent = bleedLevel + '/5';
    document.getElementById('inspBleedBar').style.width = (bleedLevel / 5 * 100) + '%';

    // Injuries
    const injuryList = document.getElementById('inspInjuryList');
    injuryList.innerHTML = '';

    if (data.injuries && data.injuries.length > 0) {
        const header = document.createElement('h3');
        header.style.cssText = 'font-size:14px;color:#38bdf8;margin-bottom:8px;';
        header.textContent = 'Injuries (' + data.injuries.length + ')';
        injuryList.appendChild(header);

        data.injuries.forEach(function(injury) {
            const item = document.createElement('div');
            item.className = 'injury-item';
            item.innerHTML = '<i class="fas fa-circle-exclamation"></i>' +
                '<span>' + (injury.zone_label || injury.zone) + ' - ' + (injury.label || injury.cause) + '</span>' +
                '<span style="margin-left:auto;font-size:11px;color:#888;">Severity: ' + Math.round(injury.severity || 0) + '</span>';
            injuryList.appendChild(item);
        });
    }

    // Broken Bones
    const boneList = document.getElementById('inspBoneList');
    boneList.innerHTML = '';

    if (data.brokenBones) {
        const bones = Object.keys(data.brokenBones).filter(function(k) { return data.brokenBones[k]; });
        if (bones.length > 0) {
            const header = document.createElement('h3');
            header.style.cssText = 'font-size:14px;color:#eab308;margin-bottom:8px;';
            header.textContent = 'Broken Bones (' + bones.length + ')';
            boneList.appendChild(header);

            bones.forEach(function(bone) {
                const item = document.createElement('div');
                item.className = 'bone-item';
                item.innerHTML = '<i class="fas fa-bone"></i><span>' + bone.replace('_', ' ') + '</span>';
                boneList.appendChild(item);
            });
        }
    }

    // Bullets
    const bulletList = document.getElementById('inspBulletList');
    bulletList.innerHTML = '';

    if (data.bullets && data.bullets.length > 0) {
        const header = document.createElement('h3');
        header.style.cssText = 'font-size:14px;color:#f97316;margin-bottom:8px;';
        header.textContent = 'Embedded Bullets (' + data.bullets.length + ')';
        bulletList.appendChild(header);

        data.bullets.forEach(function(bullet, i) {
            const item = document.createElement('div');
            item.className = 'bullet-item';
            item.innerHTML = '<i class="fas fa-crosshairs"></i><span>Bullet #' + (i + 1) + ' - ' + (bullet.zone || 'Unknown') + '</span>';
            bulletList.appendChild(item);
        });
    }
}

function closeInspection() {
    document.getElementById('patientInspection').classList.add('hidden');
}

/* =========================================================
   MDT TABLET
   ========================================================= */

function openMDT(data) {
    playerData = data || {};
    document.getElementById('mdtContainer').classList.remove('hidden');

    const userInfo = document.getElementById('mdtUserInfo');
    userInfo.querySelector('.mdt-user-name').textContent = playerData.name || 'EMS Member';
    userInfo.querySelector('.mdt-user-rank').textContent = playerData.rank || 'Trainee EMT';

    switchMDTPage('dashboard');
}

function closeMDTUI() {
    document.getElementById('mdtContainer').classList.add('hidden');
}

function closeMDT() {
    closeMDTUI();
    fetch('https://imrp_ambulancejob/closeMDT', { method: 'POST', body: JSON.stringify({}) });
}

function switchMDTPage(page) {
    currentPage = page;

    document.querySelectorAll('.mdt-page').forEach(function(p) { p.classList.remove('active'); });
    document.querySelectorAll('.mdt-nav-btn').forEach(function(b) { b.classList.remove('active'); });

    document.getElementById('page-' + page).classList.add('active');
    document.querySelector('[data-page="' + page + '"]').classList.add('active');

    loadPageData(page);
}

function loadPageData(page) {
    switch (page) {
        case 'dashboard': loadDashboard(); break;
        case 'calls': loadActiveCalls(); break;
        case 'dispatch': loadActiveCalls('dispatchTable'); break;
        case 'patients': loadPatients(); break;
        case 'insurance': loadInsurance(); break;
        case 'staff': loadStaff(); break;
        case 'logs': loadLogs(); break;
        case 'reports': loadReports(); break;
        case 'billing': loadBilling(); break;
    }
}

/* =========================================================
   DATA LOADERS
   ========================================================= */

function loadDashboard() {
    fetchNUI('getDashboardData', {}, function(data) {
        document.getElementById('statOnDuty').textContent = data.onDuty || 0;
        document.getElementById('statCalls').textContent = data.activeCalls || 0;
        document.getElementById('statPatients').textContent = data.totalPatients || 0;
        document.getElementById('statTreatments').textContent = data.todayTreatments || 0;
    });
}

function loadActiveCalls(tableId) {
    tableId = tableId || 'callsTable';
    fetchNUI('getActiveCalls', {}, function(data) {
        const container = document.getElementById(tableId);
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No active calls</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Type</th><th>Caller</th><th>Location</th><th>Status</th><th>Units</th><th>Time</th><th>Actions</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(call) {
            html += '<tr>' +
                '<td>' + (call.call_type || '-') + '</td>' +
                '<td>' + (call.caller_name || '-') + '</td>' +
                '<td>' + (call.location || '-') + '</td>' +
                '<td><span class="status-badge status-' + (call.status || 'pending') + '">' + (call.status || 'pending') + '</span></td>' +
                '<td>' + (call.responding_units || 0) + '</td>' +
                '<td>' + formatDate(call.created_at) + '</td>' +
                '<td>' +
                    (call.status !== 'completed' ?
                        '<button class="action-btn" onclick="respondCall(\'' + call.call_id + '\')"><i class="fas fa-check"></i></button> ' +
                        '<button class="action-btn" onclick="completeCall(\'' + call.call_id + '\')"><i class="fas fa-flag-checkered"></i></button>'
                    : '-') +
                '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadPatients(search) {
    fetchNUI('getPatientRecords', { search: search || '' }, function(data) {
        const container = document.getElementById('patientsTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No patient records found</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Name</th><th>Citizen ID</th><th>Blood</th><th>Pain</th><th>Status</th><th>Insurance</th><th>Last Treated</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(patient) {
            html += '<tr>' +
                '<td>' + (patient.name || '-') + '</td>' +
                '<td>' + (patient.citizenid || '-') + '</td>' +
                '<td>' + (patient.blood_level || 100) + '%</td>' +
                '<td>' + (patient.pain_level || 0) + '</td>' +
                '<td><span class="status-badge status-' + (patient.is_dead ? 'pending' : 'active') + '">' + (patient.is_dead ? 'Critical' : 'Stable') + '</span></td>' +
                '<td>' + (patient.insurance_type || 'None') + '</td>' +
                '<td>' + formatDate(patient.last_treated_at) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadInsurance() {
    fetchNUI('getInsuranceRecords', {}, function(data) {
        const container = document.getElementById('insuranceTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No insurance records</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Name</th><th>Citizen ID</th><th>Type</th><th>Discount</th><th>Purchased</th><th>Expires</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(ins) {
            html += '<tr>' +
                '<td>' + (ins.name || '-') + '</td>' +
                '<td>' + (ins.citizenid || '-') + '</td>' +
                '<td>' + (ins.insurance_type || '-').toUpperCase() + '</td>' +
                '<td>' + (ins.discount_percent || 0) + '%</td>' +
                '<td>' + formatDate(ins.purchased_at) + '</td>' +
                '<td>' + formatDate(ins.expires_at) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadStaff() {
    fetchNUI('getStaffList', {}, function(data) {
        const container = document.getElementById('staffTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No staff records</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Name</th><th>Rank</th><th>Callsign</th><th>Treatments</th><th>Revives</th><th>Hours</th><th>Last Duty</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(staff) {
            html += '<tr>' +
                '<td>' + (staff.name || '-') + '</td>' +
                '<td>' + (staff.rank_label || '-') + '</td>' +
                '<td>' + (staff.callsign || 'N/A') + '</td>' +
                '<td>' + (staff.total_treatments || 0) + '</td>' +
                '<td>' + (staff.total_revives || 0) + '</td>' +
                '<td>' + (staff.total_hours ? staff.total_hours.toFixed(1) : '0') + 'h</td>' +
                '<td>' + formatDate(staff.last_duty) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadLogs() {
    fetchNUI('getDutyLogs', {}, function(data) {
        const container = document.getElementById('logsTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No duty logs</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Name</th><th>Action</th><th>Details</th><th>Time</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(log) {
            html += '<tr>' +
                '<td>' + (log.name || '-') + '</td>' +
                '<td>' + (log.action || '-') + '</td>' +
                '<td>' + (log.details || '-') + '</td>' +
                '<td>' + formatDate(log.created_at) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadReports() {
    fetchNUI('getReports', {}, function(data) {
        const container = document.getElementById('reportsTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No reports filed</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Title</th><th>Patient</th><th>Author</th><th>Outcome</th><th>Date</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(report) {
            html += '<tr>' +
                '<td>' + (report.title || '-') + '</td>' +
                '<td>' + (report.patient_name || '-') + '</td>' +
                '<td>' + (report.author_name || '-') + '</td>' +
                '<td><span class="status-badge status-' + (report.outcome === 'treated' ? 'completed' : 'pending') + '">' + (report.outcome || '-') + '</span></td>' +
                '<td>' + formatDate(report.created_at) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

function loadBilling() {
    fetchNUI('getBillingRecords', {}, function(data) {
        const container = document.getElementById('billingTable');
        if (!data || data.length === 0) {
            container.innerHTML = '<div class="no-data">No billing records</div>';
            return;
        }

        let html = '<table class="data-table"><thead><tr>' +
            '<th>Patient</th><th>Amount</th><th>Original</th><th>Discount</th><th>Reason</th><th>Status</th><th>Date</th>' +
            '</tr></thead><tbody>';

        data.forEach(function(bill) {
            html += '<tr>' +
                '<td>' + (bill.patient_name || '-') + '</td>' +
                '<td>$' + (bill.amount || 0) + '</td>' +
                '<td>$' + (bill.original_amount || 0) + '</td>' +
                '<td>' + (bill.discount_applied || 0) + '%</td>' +
                '<td>' + (bill.reason || '-') + '</td>' +
                '<td><span class="status-badge status-' + (bill.status || 'unpaid') + '">' + (bill.status || 'unpaid') + '</span></td>' +
                '<td>' + formatDate(bill.created_at) + '</td>' +
                '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    });
}

/* =========================================================
   FORM HANDLERS
   ========================================================= */

function searchPatients() {
    const query = document.getElementById('patientSearch').value;
    loadPatients(query);
}

function showNewReport() {
    document.getElementById('newReportForm').classList.remove('hidden');
}

function hideNewReport() {
    document.getElementById('newReportForm').classList.add('hidden');
}

function submitReport() {
    const data = {
        patient_citizenid: document.getElementById('reportPatientCid').value,
        patient_name: document.getElementById('reportPatientName').value,
        title: document.getElementById('reportTitle').value,
        description: document.getElementById('reportDescription').value,
        diagnosis: document.getElementById('reportDiagnosis').value,
        outcome: document.getElementById('reportOutcome').value,
    };

    fetchNUI('saveReport', data, function() {
        hideNewReport();
        clearForm(['reportPatientCid', 'reportPatientName', 'reportTitle', 'reportDescription', 'reportDiagnosis']);
        loadReports();
    });
}

function showNewBill() {
    document.getElementById('newBillForm').classList.remove('hidden');
}

function hideNewBill() {
    document.getElementById('newBillForm').classList.add('hidden');
}

function submitBill() {
    const data = {
        patient_citizenid: document.getElementById('billPatientCid').value,
        patient_name: document.getElementById('billPatientName').value,
        amount: document.getElementById('billAmount').value,
        reason: document.getElementById('billReason').value,
    };

    fetchNUI('createBill', data, function() {
        hideNewBill();
        clearForm(['billPatientCid', 'billPatientName', 'billAmount', 'billReason']);
        loadBilling();
    });
}

function respondCall(callId) {
    fetchNUI('respondToCall', { call_id: callId }, function() {
        loadActiveCalls();
    });
}

function completeCall(callId) {
    fetchNUI('completeCall', { call_id: callId }, function() {
        loadActiveCalls();
    });
}

/* =========================================================
   UTILITIES
   ========================================================= */

function fetchNUI(event, data, callback) {
    fetch('https://imrp_ambulancejob/' + event, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    })
    .then(function(resp) { return resp.json(); })
    .then(function(result) {
        if (callback) callback(result);
    })
    .catch(function(err) {
        console.error('[IMRP EMS] NUI Error:', err);
    });
}

function formatDate(dateStr) {
    if (!dateStr) return 'N/A';
    try {
        const date = new Date(dateStr);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
        return dateStr;
    }
}

function clearForm(ids) {
    ids.forEach(function(id) {
        const el = document.getElementById(id);
        if (el) el.value = '';
    });
}

/* =========================================================
   KEYBOARD HANDLER
   ========================================================= */

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (!document.getElementById('mdtContainer').classList.contains('hidden')) {
            closeMDT();
        }
        closeInspection();
    }
});
