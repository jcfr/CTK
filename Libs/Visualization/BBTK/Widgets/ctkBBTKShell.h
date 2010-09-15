

// Qt includes
#include <QWidget>

// CTK includes
#include "ctkPimpl.h"

// BBTK includes
#include <bbtkInterpreter.h>

#include "CTKVisualizationBBTKWidgetsExport.h"

class ctkBBTKShellPrivate;

// --------------------------------------------------------------------------
class CTK_VISUALIZATION_BBTK_WIDGETS_EXPORT ctkBBTKShell : public QWidget
{
  Q_OBJECT
public:
  typedef QWidget Superclass;
  explicit ctkBBTKShell(bbtk::Interpreter::Pointer newInterpreter, QWidget* _parent = 0);
  virtual ~ctkBBTKShell(){}

  /// Prints some text on the shell.
  void printMessage(const QString&);

signals:
  void executing(bool);

public slots:
  void clear();
  void executeScript(const QString&);

protected slots:
  void printStderr(const QString&);
  void printStdout(const QString&);

  void onExecuteCommand(const QString&);

private:
  void internalExecuteCommand(const QString&);

  CTK_DECLARE_PRIVATE(ctkBBTKShell);
};
