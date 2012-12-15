/*=============================================================================

  Library: CTK

  Copyright (c) University College London

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

=============================================================================*/

#ifndef CTKCMDLINEMODULEQTUILOADER_H
#define CTKCMDLINEMODULEQTUILOADER_H

#include <QUiLoader>
#include "ctkCmdLineModuleDescription.h"
#include "ctkCommandLineModulesFrontendQtGuiExport.h"

struct ctkCmdLineModuleQtUiLoaderPrivate;

/**
 * \class ctkCmdLineModuleQtUiLoader
 * \brief Derived from QUiLoader to enable us to instantiate custom widgets at runtime,
 * where this class provides ctkCmdLineModuleQtComboBox instead of QComboBox.
 * \author m.clarkson@ucl.ac.uk
 * \ingroup CommandLineModulesFrontendQtGui_API
 */
class CTK_CMDLINEMODULEQTGUI_EXPORT ctkCmdLineModuleQtUiLoader : public QUiLoader
{

  Q_OBJECT

public:
  ctkCmdLineModuleQtUiLoader(QObject *parent=0);
  virtual ~ctkCmdLineModuleQtUiLoader();

  /**
   * \brief If className is QComboBox, instantiates ctkCmdLineModuleQtGuiComboBox and
   * otherwise delegates to base class.
   * \see QUiLoader::createWidget()
   */
  virtual QWidget* createWidget(const QString & className, QWidget * parent = 0, const QString & name = QString() );

protected:

  /**
   * \brief Get the module description for the parameters.
   * \return The XML description as a class representation.
   */
  ctkCmdLineModuleDescription description()const;

  /**
   * \brief Set the module description.
   * \see ctkCmdLineModuleFrontendQtGui::uiLoader()
   */
  void setDescription(const ctkCmdLineModuleDescription& description);

private:

  friend class ctkCmdLineModuleFrontendQtGui;

  QScopedPointer<ctkCmdLineModuleQtUiLoaderPrivate> d_ptr;

  Q_DECLARE_PRIVATE(ctkCmdLineModuleQtUiLoader)
  Q_DISABLE_COPY(ctkCmdLineModuleQtUiLoader)

}; // end class

#endif // CTKCMDLINEMODULEQTUILOADER_H
