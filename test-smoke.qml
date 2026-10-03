import QtQuick
import Quickshell
import "."

ShellRoot {
    Plugin { id: app }
    Timer {
        interval: 500; running: true
        onTriggered: {
            app.restore([
                {op: "+", value: "31.895,83", note: "Descrição longa para verificar que a data permanece alinhada", dateText: "13/10/2026"},
                {op: "−", value: "14.000,00", note: "Internet", dateText: "20/10/2026"},
                {op: "=", value: "", note: "Saldo restante", dateText: "31/10/2026"},
                {op: "novo", value: "", note: "Despesas da semana"},
                {op: "+", value: "650,00", note: "Materiais"},
                {op: "+", value: "250,00", note: "Transporte"},
                {op: "=", value: "", note: "Total de despesas"},
                {op: "novo", value: "", note: "Serviços"},
                {op: "+", value: "170,00", note: "Valor por serviço"},
                {op: "×", value: "3", note: "Quantidade"},
                {op: "=", value: "", note: "Total dos serviços"}
            ]);
            if (app.evaluation.total !== "510,00") throw new Error("QML calculation failed");
            app.edit(8, "value", "200");
            if (app.evaluation.total !== "600,00") throw new Error("Recalculation failed");
            app.undo();
            if (app.evaluation.total !== "510,00") throw new Error("Undo failed");
            app.redo();
            if (app.evaluation.total !== "600,00") throw new Error("Redo failed");
            app.undo();
            var beforeSort = JSON.stringify(app.snapshot());
            app.sortByDate();
            if (app.snapshot()[0].dateText !== "13/10/2026") throw new Error("Ascending sort failed");
            app.sortByDate();
            if (app.snapshot()[0].dateText !== "20/10/2026" || app.snapshot()[3].op !== "novo") throw new Error("Descending sort or boundary failed");
            app.undo();
            if (JSON.stringify(app.snapshot()) !== beforeSort) throw new Error("Sort undo failed");
            app.redo();
            if (app.snapshot()[0].dateText !== "20/10/2026") throw new Error("Sort redo failed");
            app.undo(); app.persist(); app.open("{}"); capture.start();
        }
    }
    Timer {
        id: capture; interval: 700
        onTriggered: app.contentItem.grabToImage(function(result) {
            result.saveToFile("/tmp/fita-preview.png");
            console.log("FITA_SMOKE_OK"); Qt.quit();
        })
    }
}
