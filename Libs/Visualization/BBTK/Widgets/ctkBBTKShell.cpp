
// Qt includes
#include <QVBoxLayout>
#include <QCoreApplication>
#include <QDebug>

// CTK includes
#include "ctkBBTKShell.h"
#include "ctkConsoleWidget.h"

// STD includes
#include <sstream>

// --------------------------------------------------------------------------
// ctkBBTKShellPrivate

// --------------------------------------------------------------------------
class ctkBBTKShellPrivate : public ctkPrivate<ctkBBTKShell>
{
public:
  ctkBBTKShellPrivate()
  {
    this->Console = 0;
    this->MultilineStatement = false;
    this->InterpreterStatus = bbtk::Interpreter::Interpreter_OK;
  }

  bool push(const QString& code);
  void resetBuffer();
  void executeCommand(const QString& command);
  void promptForInput(const QString& indent=QString());

  /// Provides a console for gathering user input and displaying BBTK output
  ctkConsoleWidget*             Console;
  bool                          MultilineStatement;
  bbtk::Interpreter::Pointer    Interpreter;
  bbtk::Interpreter::ExitStatus InterpreterStatus;

};

// --------------------------------------------------------------------------
// ctkBBTKShellPrivate methods

// --------------------------------------------------------------------------
bool ctkBBTKShellPrivate::push(const QString& code)
{
  CTK_P(ctkBBTKShell);

  std::streambuf* old_cout = std::cout.rdbuf();
  std::stringstream out_string;
  std::cout.rdbuf(out_string.rdbuf());

  try
    {
    this->InterpreterStatus = this->Interpreter->InterpretLine(code.toStdString());
    p->printStdout(QString::fromStdString(out_string.str()));
    }
  catch(const bbtk::InterpreterException& e)
    {
    std::stringstream mess;
    mess << "* ERROR : "<<e.GetErrorMessage()<<std::endl;
    if (e.IsInScriptFile())
      {
        mess << "* FILE  : \""<<e.GetScriptFile()<<"\""<<std::endl;
        mess << "* LINE  : "<<e.GetScriptLine()<<std::endl;
      }

    QString msg;
    if (e.IsInScriptFile())
      {
      msg = QString("%1\n* FILE : \"%2\"\n* LINE : %3").
            arg(QString::fromStdString(e.GetErrorMessage()).
            arg(QString::fromStdString(e.GetScriptFile())).
            arg(e.GetScriptLine()));
      }
    else
      {
      msg = QString("%1").arg(QString::fromStdString(e.GetErrorMessage()));
      }
    p->printStderr(msg);
    }
  catch(...)
    {
    p->printStderr(QString("%1 : Unknown command").arg(code));
    }

  std::cout.rdbuf(old_cout);

  return false;
}

//----------------------------------------------------------------------------
void ctkBBTKShellPrivate::resetBuffer()
{

}

//----------------------------------------------------------------------------
void ctkBBTKShellPrivate::executeCommand(const QString& command)
{
  this->MultilineStatement = this->push(command);
}

//----------------------------------------------------------------------------
void ctkBBTKShellPrivate::promptForInput(const QString& indent)
{
  QTextCharFormat format = this->Console->getFormat();
  format.setForeground(QColor(0, 0, 0));
  this->Console->setFormat(format);

  if(!this->MultilineStatement)
    {
    this->Console->prompt(">>> ");
    }
  else
    {
    this->Console->prompt("... ");
    }
  this->Console->printCommand(indent);
}

// --------------------------------------------------------------------------
// ctkBBTKShell methods

// --------------------------------------------------------------------------
ctkBBTKShell::ctkBBTKShell(bbtk::Interpreter::Pointer newInterpreter, QWidget* newParent):
    Superclass(newParent)
{
  CTK_INIT_PRIVATE(ctkBBTKShell);
  CTK_D(ctkBBTKShell);
  d->Console = new ctkConsoleWidget();
  d->Interpreter = newInterpreter;

  // We tell the interpreter to throw exceptions on error
  d->Interpreter->SetThrow(true);

  // Layout UI
  QVBoxLayout* const boxLayout = new QVBoxLayout(this);
  boxLayout->setMargin(0);
  boxLayout->addWidget(d->Console);

  this->setObjectName("bbtkShell");

  QObject::connect(
    d->Console, SIGNAL(executeCommand(const QString&)),
    this, SLOT(onExecuteCommand(const QString&)));

  QTextCharFormat format = d->Console->getFormat();
  format.setForeground(QColor(0, 0, 255));
  d->Console->setFormat(format);
  d->Console->printString(
    QString("BBTK %1\n").arg(BBTK_VERSION_STRING));
  d->promptForInput();

  //this->connect(PythonQt::self(), SIGNAL(pythonStdOut(const QString&)),
  //              SLOT(printStdout(const QString&)));
  //this->connect(PythonQt::self(), SIGNAL(pythonStdErr(const QString&)),
  //              SLOT(printStderr(const QString&)));
}

//----------------------------------------------------------------------------
void ctkBBTKShell::clear()
{
  CTK_D(ctkBBTKShell);
  d->Console->clear();
  d->promptForInput();
}

//----------------------------------------------------------------------------
void ctkBBTKShell::executeScript(const QString& script)
{
  CTK_D(ctkBBTKShell);
  Q_UNUSED(script);

  this->printStdout("\n");
  emit this->executing(true);
//   d->Interpreter->RunSimpleString(
//     script.toAscii().data());
  emit this->executing(false);
  d->promptForInput();
}

//----------------------------------------------------------------------------
void ctkBBTKShell::printStdout(const QString& text)
{
  CTK_D(ctkBBTKShell);
  QTextCharFormat format = d->Console->getFormat();
  format.setForeground(QColor(0, 150, 0));
  d->Console->setFormat(format);

  d->Console->printString(text);

  QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
}

//----------------------------------------------------------------------------
void ctkBBTKShell::printMessage(const QString& text)
{
  CTK_D(ctkBBTKShell);
  QTextCharFormat format = d->Console->getFormat();
  format.setForeground(QColor(0, 0, 150));
  d->Console->setFormat(format);

  d->Console->printString(text);
}

//----------------------------------------------------------------------------
void ctkBBTKShell::printStderr(const QString& text)
{
  CTK_D(ctkBBTKShell);
  QTextCharFormat format = d->Console->getFormat();
  format.setForeground(QColor(255, 0, 0));
  d->Console->setFormat(format);

  d->Console->printString(text);

  QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
}

//----------------------------------------------------------------------------
void ctkBBTKShell::onExecuteCommand(const QString& Command)
{
  CTK_D(ctkBBTKShell);
  QString command = Command;
  command.replace(QRegExp("\\s*$"), "");
  this->internalExecuteCommand(command);

  // Find the indent for the command.
  QRegExp regExp("^(\\s+)");
  QString indent;
  if (regExp.indexIn(command) != -1)
    {
    indent = regExp.cap(1);
    }
  d->promptForInput(indent);
}

//----------------------------------------------------------------------------
void ctkBBTKShell::internalExecuteCommand(const QString& command)
{
  CTK_D(ctkBBTKShell);
  emit this->executing(true);
  d->executeCommand(command);
  emit this->executing(false);
}
