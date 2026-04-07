package com.washingtonclimaco.task_manager_appacademia;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.rule.ActivityTestRule;
import org.junit.ClassRule;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import tools.fastlane.screengrab.Screengrab;
import tools.fastlane.screengrab.locale.LocaleTestRule;

@RunWith(AndroidJUnit4.class)
public class ScreenshotTest {

    @ClassRule
    public static final LocaleTestRule localeTestRule = new LocaleTestRule();

    @Rule
    public ActivityTestRule<MainActivity> activityRule =
        new ActivityTestRule<>(MainActivity.class);

    @Test
    public void testTakeScreenshots() {
        Screengrab.screenshot("01_login");
        // Adicione interações e mais screenshots conforme necessário:
        // Screengrab.screenshot("02_dashboard");
        // Screengrab.screenshot("03_detalhes");
    }
}
